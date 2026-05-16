package services_test

import (
	"context"
	"testing"
	"time"

	appauth "github.com/asadlive84/fitness-care-bagerhat/internal/auth"
	"github.com/asadlive84/fitness-care-bagerhat/internal/config"
	"github.com/asadlive84/fitness-care-bagerhat/internal/models"
	"github.com/asadlive84/fitness-care-bagerhat/internal/repositories"
	"github.com/asadlive84/fitness-care-bagerhat/internal/services"
	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"golang.org/x/crypto/bcrypt"
)

// ── Fakes ─────────────────────────────────────────────────────────────────────

type fakeMemberRepo struct {
	creds *models.MemberCredentials
	member *models.Member
}

func (f *fakeMemberRepo) GetMemberCredentials(_ context.Context, _ string) (*models.MemberCredentials, error) {
	if f.creds == nil {
		return nil, assert.AnError
	}
	return f.creds, nil
}
func (f *fakeMemberRepo) GetByID(_ context.Context, _ uuid.UUID) (*models.Member, error) {
	return f.member, nil
}
func (f *fakeMemberRepo) GetByPhone(_ context.Context, _ string) (*models.Member, error) {
	return f.member, nil
}
func (f *fakeMemberRepo) Create(_ context.Context, _ *models.Member, _ string) error { return nil }
func (f *fakeMemberRepo) List(_ context.Context, _ models.MemberFilter) ([]*models.Member, int64, error) {
	return nil, 0, nil
}
func (f *fakeMemberRepo) Update(_ context.Context, _ *models.Member) error        { return nil }
func (f *fakeMemberRepo) UpdateStatus(_ context.Context, _ uuid.UUID, _ string) error { return nil }
func (f *fakeMemberRepo) UpdatePassword(_ context.Context, _ uuid.UUID, _ string) error { return nil }
func (f *fakeMemberRepo) ListExpiringSoon(_ context.Context, _ int) ([]*models.Member, error) {
	return nil, nil
}
func (f *fakeMemberRepo) ResetPasswordByAdmin(_ context.Context, _ uuid.UUID, _ string) error {
	return nil
}
func (f *fakeMemberRepo) Delete(_ context.Context, _ uuid.UUID) error { return nil }

var _ repositories.MemberRepository = (*fakeMemberRepo)(nil)

type fakeAdminRepo struct {
	creds *models.AdminCredentials
}

func (f *fakeAdminRepo) GetAdminCredentials(_ context.Context, _ string) (*models.AdminCredentials, error) {
	if f.creds == nil {
		return nil, assert.AnError
	}
	return f.creds, nil
}
func (f *fakeAdminRepo) Create(_ context.Context, _ *models.Admin, _ string) error { return nil }
func (f *fakeAdminRepo) GetByID(_ context.Context, _ uuid.UUID) (*models.Admin, error) {
	return nil, nil
}
func (f *fakeAdminRepo) GetByEmail(_ context.Context, _ string) (*models.Admin, error) {
	return nil, nil
}
func (f *fakeAdminRepo) UpdatePassword(_ context.Context, _ uuid.UUID, _ string) error { return nil }

var _ repositories.AdminRepository = (*fakeAdminRepo)(nil)

// ── Helpers ───────────────────────────────────────────────────────────────────

func testJWTManager() *appauth.Manager {
	return appauth.NewManager(config.JWTConfig{
		AccessSecret:  "test_access_secret_min_32_chars_xx",
		RefreshSecret: "test_refresh_secret_min_32_chars_x",
		AccessTTL:     15 * time.Minute,
		RefreshTTL:    7 * 24 * time.Hour,
	})
}

func hashPassword(t *testing.T, plain string) string {
	t.Helper()
	h, err := bcrypt.GenerateFromPassword([]byte(plain), bcrypt.MinCost)
	require.NoError(t, err)
	return string(h)
}

// ── Tests ─────────────────────────────────────────────────────────────────────

func TestLoginAdmin_Success(t *testing.T) {
	adminID := uuid.New()
	svc := services.NewAuthService(
		&fakeMemberRepo{},
		&fakeAdminRepo{creds: &models.AdminCredentials{
			AdminID:      adminID,
			PasswordHash: hashPassword(t, "correct_password"),
		}},
		testJWTManager(),
	)

	pair, err := svc.LoginAdmin(context.Background(), "owner@gym.bd", "correct_password")
	require.NoError(t, err)
	assert.NotEmpty(t, pair.AccessToken)
	assert.NotEmpty(t, pair.RefreshToken)
	assert.Equal(t, int64(15*60), pair.ExpiresIn)
}

func TestLoginAdmin_WrongPassword(t *testing.T) {
	svc := services.NewAuthService(
		&fakeMemberRepo{},
		&fakeAdminRepo{creds: &models.AdminCredentials{
			AdminID:      uuid.New(),
			PasswordHash: hashPassword(t, "correct_password"),
		}},
		testJWTManager(),
	)

	_, err := svc.LoginAdmin(context.Background(), "owner@gym.bd", "wrong_password")
	require.Error(t, err)
	assert.ErrorIs(t, err, services.ErrInvalidCredentials)
}

func TestLoginAdmin_NotFound(t *testing.T) {
	svc := services.NewAuthService(
		&fakeMemberRepo{},
		&fakeAdminRepo{creds: nil}, // simulates DB returning not-found
		testJWTManager(),
	)

	_, err := svc.LoginAdmin(context.Background(), "nobody@gym.bd", "any")
	assert.ErrorIs(t, err, services.ErrInvalidCredentials)
}

func TestLoginMember_Success(t *testing.T) {
	memberID := uuid.New()
	svc := services.NewAuthService(
		&fakeMemberRepo{creds: &models.MemberCredentials{
			MemberID:           memberID,
			PasswordHash:       hashPassword(t, "pass1234"),
			Status:             "active",
			MustChangePassword: false,
		}},
		&fakeAdminRepo{},
		testJWTManager(),
	)

	result, err := svc.LoginMember(context.Background(), "01711000001", "pass1234")
	require.NoError(t, err)
	assert.False(t, result.MustChangePassword)
	assert.NotEmpty(t, result.AccessToken)
}

func TestLoginMember_Inactive(t *testing.T) {
	svc := services.NewAuthService(
		&fakeMemberRepo{creds: &models.MemberCredentials{
			MemberID:     uuid.New(),
			PasswordHash: hashPassword(t, "pass1234"),
			Status:       "inactive",
		}},
		&fakeAdminRepo{},
		testJWTManager(),
	)

	_, err := svc.LoginMember(context.Background(), "01711000001", "pass1234")
	assert.ErrorIs(t, err, services.ErrMemberInactive)
}

func TestLoginMember_MustChangePassword(t *testing.T) {
	svc := services.NewAuthService(
		&fakeMemberRepo{creds: &models.MemberCredentials{
			MemberID:           uuid.New(),
			PasswordHash:       hashPassword(t, "temp123"),
			Status:             "active",
			MustChangePassword: true,
		}},
		&fakeAdminRepo{},
		testJWTManager(),
	)

	result, err := svc.LoginMember(context.Background(), "01711000001", "temp123")
	require.NoError(t, err)
	assert.True(t, result.MustChangePassword, "flag must be set for first-login flow")
}

func TestRefreshToken_Success(t *testing.T) {
	mgr := testJWTManager()
	svc := services.NewAuthService(&fakeMemberRepo{}, &fakeAdminRepo{}, mgr)

	// Obtain a real refresh token first.
	pair, err := mgr.GenerateTokenPair(uuid.NewString(), appauth.RoleMember)
	require.NoError(t, err)

	newPair, err := svc.RefreshToken(context.Background(), pair.RefreshToken)
	require.NoError(t, err)
	assert.NotEmpty(t, newPair.AccessToken)
	assert.NotEmpty(t, newPair.RefreshToken)
	// Verify the new access token is structurally valid.
	claims, err := mgr.ValidateAccessToken(newPair.AccessToken)
	require.NoError(t, err)
	assert.Equal(t, appauth.RoleMember, claims.Role)
}

func TestRefreshToken_InvalidToken(t *testing.T) {
	svc := services.NewAuthService(&fakeMemberRepo{}, &fakeAdminRepo{}, testJWTManager())

	_, err := svc.RefreshToken(context.Background(), "not.a.valid.token")
	assert.ErrorIs(t, err, services.ErrInvalidCredentials)
}

func TestRefreshToken_AccessTokenRejected(t *testing.T) {
	mgr := testJWTManager()
	svc := services.NewAuthService(&fakeMemberRepo{}, &fakeAdminRepo{}, mgr)

	// Using an ACCESS token where a REFRESH token is expected must fail.
	pair, err := mgr.GenerateTokenPair(uuid.NewString(), appauth.RoleMember)
	require.NoError(t, err)

	_, err = svc.RefreshToken(context.Background(), pair.AccessToken)
	assert.Error(t, err, "access token must not be accepted as a refresh token")
}
