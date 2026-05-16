package services

import (
	"context"
	"fmt"

	"github.com/asadlive84/fitness-care-bagerhat/internal/auth"
	"github.com/asadlive84/fitness-care-bagerhat/internal/repositories"
	"github.com/google/uuid"
	"golang.org/x/crypto/bcrypt"
)

// AuthService handles login, token refresh, and password management.
type AuthService struct {
	members repositories.MemberRepository
	admins  repositories.AdminRepository
	jwt     *auth.Manager
}

// NewAuthService constructs an AuthService with its dependencies.
func NewAuthService(
	members repositories.MemberRepository,
	admins repositories.AdminRepository,
	jwt *auth.Manager,
) *AuthService {
	return &AuthService{members: members, admins: admins, jwt: jwt}
}

// LoginAdmin verifies admin credentials and returns a token pair.
func (s *AuthService) LoginAdmin(ctx context.Context, email, password string) (*auth.TokenPair, error) {
	creds, err := s.admins.GetAdminCredentials(ctx, email)
	if err != nil {
		// Mask whether the account exists.
		return nil, ErrInvalidCredentials
	}

	if err := bcrypt.CompareHashAndPassword([]byte(creds.PasswordHash), []byte(password)); err != nil {
		return nil, ErrInvalidCredentials
	}

	pair, err := s.jwt.GenerateTokenPair(creds.AdminID.String(), auth.RoleAdmin)
	if err != nil {
		return nil, fmt.Errorf("generate admin tokens: %w", err)
	}
	return pair, nil
}

// MemberLoginResult bundles the token pair with the must-change-password flag.
type MemberLoginResult struct {
	*auth.TokenPair
	MustChangePassword bool `json:"must_change_password"`
}

// LoginMember verifies member credentials and returns a token pair.
// The MustChangePassword flag tells the client to redirect to the password
// change screen before allowing normal app access.
func (s *AuthService) LoginMember(ctx context.Context, phone, password string) (*MemberLoginResult, error) {
	creds, err := s.members.GetMemberCredentials(ctx, phone)
	if err != nil {
		return nil, ErrInvalidCredentials
	}

	if creds.Status == "inactive" {
		return nil, ErrMemberInactive
	}

	if err := bcrypt.CompareHashAndPassword([]byte(creds.PasswordHash), []byte(password)); err != nil {
		return nil, ErrInvalidCredentials
	}

	pair, err := s.jwt.GenerateTokenPair(creds.MemberID.String(), auth.RoleMember)
	if err != nil {
		return nil, fmt.Errorf("generate member tokens: %w", err)
	}

	return &MemberLoginResult{
		TokenPair:          pair,
		MustChangePassword: creds.MustChangePassword,
	}, nil
}

// RefreshToken validates a refresh token and issues a new token pair (rotation).
func (s *AuthService) RefreshToken(_ context.Context, refreshToken string) (*auth.TokenPair, error) {
	claims, err := s.jwt.ValidateRefreshToken(refreshToken)
	if err != nil {
		return nil, ErrInvalidCredentials // reuse credential error for token problems
	}

	pair, err := s.jwt.GenerateTokenPair(claims.Subject, claims.Role)
	if err != nil {
		return nil, fmt.Errorf("generate refreshed tokens: %w", err)
	}
	return pair, nil
}

// ChangeMemberPassword verifies the current password then stores the new hash.
func (s *AuthService) ChangeMemberPassword(
	ctx context.Context,
	memberID uuid.UUID,
	currentPassword, newPassword string,
) error {
	// Fetch the member to get phone (cached), then fetch credentials from DB.
	member, err := s.members.GetByID(ctx, memberID)
	if err != nil {
		return fmt.Errorf("get member: %w", err)
	}

	creds, err := s.members.GetMemberCredentials(ctx, member.Phone)
	if err != nil {
		return fmt.Errorf("get member credentials: %w", err)
	}

	if err := bcrypt.CompareHashAndPassword([]byte(creds.PasswordHash), []byte(currentPassword)); err != nil {
		return ErrInvalidCredentials
	}

	newHash, err := bcrypt.GenerateFromPassword([]byte(newPassword), 12)
	if err != nil {
		return fmt.Errorf("hash new password: %w", err)
	}

	return s.members.UpdatePassword(ctx, memberID, string(newHash))
}
