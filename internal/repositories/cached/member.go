// Package cached contains repository decorators that wrap a Postgres repository
// with Redis cache-aside (read) + write-through/invalidate (write) logic.
//
// Cache-aside contract:
//   1. Try Redis.
//   2. On miss → call inner (Postgres) repo → store result with TTL.
//   3. On write → write Postgres first → invalidate/update Redis on success.
//   4. Redis errors never break the request — log and fall through to DB.
package cached

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"time"

	"github.com/asadlive84/fitness-care-bagerhat/internal/cache"
	"github.com/asadlive84/fitness-care-bagerhat/internal/models"
	"github.com/asadlive84/fitness-care-bagerhat/internal/repositories"
	"github.com/google/uuid"
)

const memberTTL = time.Hour

// MemberRepo wraps a MemberRepository, adding Redis caching for GetByID and GetByPhone.
type MemberRepo struct {
	db    repositories.MemberRepository
	cache *cache.Client
	log   *slog.Logger
}

func NewMemberRepo(db repositories.MemberRepository, c *cache.Client, log *slog.Logger) *MemberRepo {
	return &MemberRepo{db: db, cache: c, log: log}
}

// GetByID implements cache-aside for member:{id}.
func (r *MemberRepo) GetByID(ctx context.Context, id uuid.UUID) (*models.Member, error) {
	key := memberKey(id)

	var m models.Member
	if err := r.cache.GetJSON(ctx, key, &m); err == nil {
		return &m, nil // cache HIT
	} else if !errors.Is(err, cache.ErrCacheMiss) {
		r.log.WarnContext(ctx, "cache get member by id", "error", err, "key", key)
	}

	// Cache miss — fetch from DB.
	member, err := r.db.GetByID(ctx, id)
	if err != nil {
		return nil, err
	}

	if setErr := r.cache.SetJSON(ctx, key, member, memberTTL); setErr != nil {
		r.log.WarnContext(ctx, "cache set member by id", "error", setErr, "key", key)
	}
	return member, nil
}

// GetByPhone implements cache-aside for member:phone:{phone}.
func (r *MemberRepo) GetByPhone(ctx context.Context, phone string) (*models.Member, error) {
	key := memberPhoneKey(phone)

	var m models.Member
	if err := r.cache.GetJSON(ctx, key, &m); err == nil {
		return &m, nil // cache HIT
	} else if !errors.Is(err, cache.ErrCacheMiss) {
		r.log.WarnContext(ctx, "cache get member by phone", "error", err, "key", key)
	}

	member, err := r.db.GetByPhone(ctx, phone)
	if err != nil {
		return nil, err
	}

	if setErr := r.cache.SetJSON(ctx, key, member, memberTTL); setErr != nil {
		r.log.WarnContext(ctx, "cache set member by phone", "error", setErr, "key", key)
	}
	return member, nil
}

// GetMemberCredentials always hits the DB — credentials must never be cached.
func (r *MemberRepo) GetMemberCredentials(ctx context.Context, phone string) (*models.MemberCredentials, error) {
	return r.db.GetMemberCredentials(ctx, phone)
}

// Create writes to DB. No cache population — the member is new and nothing
// is cached for it yet.
func (r *MemberRepo) Create(ctx context.Context, m *models.Member, passwordHash string) error {
	return r.db.Create(ctx, m, passwordHash)
}

// Update writes to DB then invalidates the affected cache keys.
func (r *MemberRepo) Update(ctx context.Context, m *models.Member) error {
	if err := r.db.Update(ctx, m); err != nil {
		return err
	}
	r.invalidateMember(ctx, m.ID, m.Phone)
	return nil
}

// UpdateStatus writes to DB then invalidates member:{id}.
func (r *MemberRepo) UpdateStatus(ctx context.Context, id uuid.UUID, status string) error {
	if err := r.db.UpdateStatus(ctx, id, status); err != nil {
		return err
	}
	r.deleteKey(ctx, memberKey(id))
	return nil
}

// UpdatePassword writes to DB then invalidates member:{id}.
func (r *MemberRepo) UpdatePassword(ctx context.Context, id uuid.UUID, hash string) error {
	if err := r.db.UpdatePassword(ctx, id, hash); err != nil {
		return err
	}
	r.deleteKey(ctx, memberKey(id))
	return nil
}

// ResetPasswordByAdmin writes to DB (setting must_change_password=true) then invalidates cache.
func (r *MemberRepo) ResetPasswordByAdmin(ctx context.Context, id uuid.UUID, hash string) error {
	if err := r.db.ResetPasswordByAdmin(ctx, id, hash); err != nil {
		return err
	}
	r.deleteKey(ctx, memberKey(id))
	return nil
}

// List is never cached (too many filter combinations).
func (r *MemberRepo) List(ctx context.Context, f models.MemberFilter) ([]*models.Member, int64, error) {
	return r.db.List(ctx, f)
}

// ListExpiringSoon is never cached — used by scheduler, needs fresh data.
func (r *MemberRepo) ListExpiringSoon(ctx context.Context, days int) ([]*models.Member, error) {
	return r.db.ListExpiringSoon(ctx, days)
}

// Delete removes the member from DB then purges their cache entries.
func (r *MemberRepo) Delete(ctx context.Context, id uuid.UUID) error {
	// Fetch phone before deletion so we can invalidate the phone key.
	m, err := r.db.GetByID(ctx, id)
	if err != nil {
		return err
	}
	if err := r.db.Delete(ctx, id); err != nil {
		return err
	}
	r.invalidateMember(ctx, id, m.Phone)
	return nil
}

func (r *MemberRepo) InvalidateCache(ctx context.Context, id uuid.UUID, phone string) error {
	r.invalidateMember(ctx, id, phone)
	return nil
}

// ── helpers ──────────────────────────────────────────────────────────────────

func (r *MemberRepo) invalidateMember(ctx context.Context, id uuid.UUID, phone string) {
	r.deleteKey(ctx, memberKey(id))
	r.deleteKey(ctx, memberPhoneKey(phone))
}

func (r *MemberRepo) deleteKey(ctx context.Context, key string) {
	if err := r.cache.Delete(ctx, key); err != nil {
		r.log.WarnContext(ctx, "cache delete key", "error", err, "key", key)
	}
}

func memberKey(id uuid.UUID) string      { return fmt.Sprintf("member:%s", id) }
func memberPhoneKey(phone string) string  { return fmt.Sprintf("member:phone:%s", phone) }
