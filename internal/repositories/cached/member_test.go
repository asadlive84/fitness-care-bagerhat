package cached_test

import (
	"context"
	"log/slog"
	"sync/atomic"
	"testing"
	"time"

	"github.com/asadlive84/fitness-care-bagerhat/internal/cache"
	"github.com/asadlive84/fitness-care-bagerhat/internal/config"
	"github.com/asadlive84/fitness-care-bagerhat/internal/models"
	"github.com/asadlive84/fitness-care-bagerhat/internal/repositories"
	"github.com/asadlive84/fitness-care-bagerhat/internal/repositories/cached"
	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// fakeMemberRepo is an in-memory stub of repositories.MemberRepository.
// It counts how many times the DB is called so we can assert cache behaviour.
type fakeMemberRepo struct {
	members   map[uuid.UUID]*models.Member
	byPhone   map[string]*models.Member
	callCount atomic.Int64
}

func newFakeMemberRepo() *fakeMemberRepo {
	return &fakeMemberRepo{
		members: make(map[uuid.UUID]*models.Member),
		byPhone: make(map[string]*models.Member),
	}
}

func (f *fakeMemberRepo) Create(_ context.Context, m *models.Member, _ string) error {
	f.callCount.Add(1)
	f.members[m.ID] = m
	f.byPhone[m.Phone] = m
	return nil
}

func (f *fakeMemberRepo) GetByID(_ context.Context, id uuid.UUID) (*models.Member, error) {
	f.callCount.Add(1)
	m, ok := f.members[id]
	if !ok {
		return nil, assert.AnError
	}
	return m, nil
}

func (f *fakeMemberRepo) GetByPhone(_ context.Context, phone string) (*models.Member, error) {
	f.callCount.Add(1)
	m, ok := f.byPhone[phone]
	if !ok {
		return nil, assert.AnError
	}
	return m, nil
}

func (f *fakeMemberRepo) GetMemberCredentials(_ context.Context, _ string) (*models.MemberCredentials, error) {
	f.callCount.Add(1)
	return &models.MemberCredentials{}, nil
}

func (f *fakeMemberRepo) List(_ context.Context, _ models.MemberFilter) ([]*models.Member, int64, error) {
	f.callCount.Add(1)
	return nil, 0, nil
}

func (f *fakeMemberRepo) Update(_ context.Context, m *models.Member) error {
	f.callCount.Add(1)
	f.members[m.ID] = m
	f.byPhone[m.Phone] = m
	return nil
}

func (f *fakeMemberRepo) UpdateStatus(_ context.Context, id uuid.UUID, status string) error {
	f.callCount.Add(1)
	if m, ok := f.members[id]; ok {
		m.Status = status
	}
	return nil
}

func (f *fakeMemberRepo) UpdatePassword(_ context.Context, _ uuid.UUID, _ string) error {
	f.callCount.Add(1)
	return nil
}

func (f *fakeMemberRepo) ListExpiringSoon(_ context.Context, _ int) ([]*models.Member, error) {
	f.callCount.Add(1)
	return nil, nil
}

func (f *fakeMemberRepo) ResetPasswordByAdmin(_ context.Context, _ uuid.UUID, _ string) error {
	f.callCount.Add(1)
	return nil
}

func (f *fakeMemberRepo) Delete(_ context.Context, id uuid.UUID) error {
	f.callCount.Add(1)
	if m, ok := f.members[id]; ok {
		delete(f.byPhone, m.Phone)
		delete(f.members, id)
	}
	return nil
}

func (f *fakeMemberRepo) InvalidateCache(_ context.Context, _ uuid.UUID, _ string) error {
	f.callCount.Add(1)
	return nil
}

// compile-time interface check
var _ repositories.MemberRepository = (*fakeMemberRepo)(nil)

// ── Helpers ───────────────────────────────────────────────────────────────────

func newTestRedis(t *testing.T) *cache.Client {
	t.Helper()
	c, err := cache.New(config.RedisConfig{
		Addr:         "localhost:6379",
		DB:           14, // isolated test DB
		DialTimeout:  2 * time.Second,
		ReadTimeout:  500 * time.Millisecond,
		WriteTimeout: 500 * time.Millisecond,
		PoolSize:     2,
	})
	if err != nil {
		t.Skipf("redis not available: %v", err)
	}
	t.Cleanup(func() { c.Close() })
	return c
}

func newTestMember() *models.Member {
	return &models.Member{
		ID:     uuid.New(),
		Name:   "Rahim Uddin",
		Phone:  "01711" + uuid.NewString()[:6], // unique per test run
		Status: "active",
	}
}

// ── Tests ─────────────────────────────────────────────────────────────────────

// TestCacheMissHitsDB verifies that the first GetByID call reaches the DB.
func TestCacheMissHitsDB(t *testing.T) {
	rc := newTestRedis(t)
	fake := newFakeMemberRepo()
	member := newTestMember()
	fake.members[member.ID] = member

	repo := cached.NewMemberRepo(fake, rc, slog.Default())
	ctx := context.Background()

	result, err := repo.GetByID(ctx, member.ID)
	require.NoError(t, err)
	assert.Equal(t, member.ID, result.ID)
	assert.Equal(t, int64(1), fake.callCount.Load(), "DB should be called on cache miss")
}

// TestCacheHitSkipsDB verifies that the second GetByID call is served from Redis.
func TestCacheHitSkipsDB(t *testing.T) {
	rc := newTestRedis(t)
	fake := newFakeMemberRepo()
	member := newTestMember()
	fake.members[member.ID] = member

	repo := cached.NewMemberRepo(fake, rc, slog.Default())
	ctx := context.Background()

	// First call populates the cache.
	_, err := repo.GetByID(ctx, member.ID)
	require.NoError(t, err)

	dbCallsAfterFirstRead := fake.callCount.Load()

	// Second call must be served from cache.
	result, err := repo.GetByID(ctx, member.ID)
	require.NoError(t, err)
	assert.Equal(t, member.ID, result.ID)
	assert.Equal(t, dbCallsAfterFirstRead, fake.callCount.Load(), "DB must NOT be called on cache hit")
}

// TestUpdateInvalidatesCache verifies that Update evicts the cached entry.
func TestUpdateInvalidatesCache(t *testing.T) {
	rc := newTestRedis(t)
	fake := newFakeMemberRepo()
	member := newTestMember()
	fake.members[member.ID] = member
	fake.byPhone[member.Phone] = member

	repo := cached.NewMemberRepo(fake, rc, slog.Default())
	ctx := context.Background()

	// Warm the cache.
	_, err := repo.GetByID(ctx, member.ID)
	require.NoError(t, err)

	callsBeforeUpdate := fake.callCount.Load()

	// Mutate and update.
	member.Name = "Updated Name"
	require.NoError(t, repo.Update(ctx, member))

	// Next GetByID must miss cache and re-query DB.
	result, err := repo.GetByID(ctx, member.ID)
	require.NoError(t, err)
	assert.Equal(t, member.ID, result.ID)
	assert.Greater(t, fake.callCount.Load(), callsBeforeUpdate+1, // +1 for Update, +1 for GetByID
		"DB should be called again after cache invalidation")
}

// TestPhoneCacheMissHitsDB verifies cache-aside for GetByPhone.
func TestPhoneCacheMissHitsDB(t *testing.T) {
	rc := newTestRedis(t)
	fake := newFakeMemberRepo()
	member := newTestMember()
	fake.members[member.ID] = member
	fake.byPhone[member.Phone] = member

	repo := cached.NewMemberRepo(fake, rc, slog.Default())
	ctx := context.Background()

	result, err := repo.GetByPhone(ctx, member.Phone)
	require.NoError(t, err)
	assert.Equal(t, member.Phone, result.Phone)

	// Second call → cache hit.
	callsAfterFirst := fake.callCount.Load()
	_, err = repo.GetByPhone(ctx, member.Phone)
	require.NoError(t, err)
	assert.Equal(t, callsAfterFirst, fake.callCount.Load(), "second GetByPhone must be served from cache")
}

// TestGetCredentialsNeverCached verifies credentials always go to DB.
func TestGetCredentialsNeverCached(t *testing.T) {
	rc := newTestRedis(t)
	fake := newFakeMemberRepo()

	repo := cached.NewMemberRepo(fake, rc, slog.Default())
	ctx := context.Background()

	repo.GetMemberCredentials(ctx, "01711000001") //nolint:errcheck
	repo.GetMemberCredentials(ctx, "01711000001") //nolint:errcheck

	assert.Equal(t, int64(2), fake.callCount.Load(), "GetMemberCredentials must always hit DB")
}
