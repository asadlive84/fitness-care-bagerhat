// Package auth provides JWT token generation and validation.
package auth

import (
	"errors"
	"fmt"
	"time"

	"github.com/asadlive84/fitness-care-bagerhat/internal/config"
	"github.com/golang-jwt/jwt/v5"
)

// Role constants used across the application.
const (
	RoleAdmin      = "admin"
	RoleSuperAdmin = "superadmin"
	RoleMember     = "member"
)

// tokenType distinguishes access from refresh tokens so a refresh token
// cannot be used as an access token and vice-versa.
const (
	tokenTypeAccess  = "access"
	tokenTypeRefresh = "refresh"
)

// Claims is the JWT payload stored in every token.
type Claims struct {
	Role string `json:"role"`
	Type string `json:"type"` // "access" | "refresh"
	jwt.RegisteredClaims
}

// TokenPair is the response returned after a successful login or refresh.
type TokenPair struct {
	AccessToken  string `json:"access_token"`
	RefreshToken string `json:"refresh_token"`
	ExpiresIn    int64  `json:"expires_in"` // seconds until access token expires
}

// Manager handles JWT creation and validation.
type Manager struct {
	accessSecret  []byte
	refreshSecret []byte
	accessTTL     time.Duration
	refreshTTL    time.Duration
}

// NewManager creates a Manager from application config.
func NewManager(cfg config.JWTConfig) *Manager {
	return &Manager{
		accessSecret:  []byte(cfg.AccessSecret),
		refreshSecret: []byte(cfg.RefreshSecret),
		accessTTL:     cfg.AccessTTL,
		refreshTTL:    cfg.RefreshTTL,
	}
}

// GenerateTokenPair issues a new access + refresh token pair for the given
// user ID and role.
func (m *Manager) GenerateTokenPair(userID, role string) (*TokenPair, error) {
	now := time.Now()

	accessToken, err := m.sign(m.accessSecret, Claims{
		Role: role,
		Type: tokenTypeAccess,
		RegisteredClaims: jwt.RegisteredClaims{
			Subject:   userID,
			IssuedAt:  jwt.NewNumericDate(now),
			ExpiresAt: jwt.NewNumericDate(now.Add(m.accessTTL)),
		},
	})
	if err != nil {
		return nil, fmt.Errorf("sign access token: %w", err)
	}

	refreshToken, err := m.sign(m.refreshSecret, Claims{
		Role: role,
		Type: tokenTypeRefresh,
		RegisteredClaims: jwt.RegisteredClaims{
			Subject:   userID,
			IssuedAt:  jwt.NewNumericDate(now),
			ExpiresAt: jwt.NewNumericDate(now.Add(m.refreshTTL)),
		},
	})
	if err != nil {
		return nil, fmt.Errorf("sign refresh token: %w", err)
	}

	return &TokenPair{
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
		ExpiresIn:    int64(m.accessTTL.Seconds()),
	}, nil
}

// ValidateAccessToken parses and validates an access token.
// Returns ErrInvalidToken for any validation failure.
func (m *Manager) ValidateAccessToken(tokenStr string) (*Claims, error) {
	return m.parse(tokenStr, m.accessSecret, tokenTypeAccess)
}

// ValidateRefreshToken parses and validates a refresh token.
func (m *Manager) ValidateRefreshToken(tokenStr string) (*Claims, error) {
	return m.parse(tokenStr, m.refreshSecret, tokenTypeRefresh)
}

// ErrInvalidToken is returned when a token is missing, malformed, or expired.
var ErrInvalidToken = errors.New("invalid or expired token")

// ── private ───────────────────────────────────────────────────────────────────

func (m *Manager) sign(secret []byte, claims Claims) (string, error) {
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString(secret)
}

func (m *Manager) parse(tokenStr string, secret []byte, expectedType string) (*Claims, error) {
	token, err := jwt.ParseWithClaims(tokenStr, &Claims{}, func(t *jwt.Token) (any, error) {
		if _, ok := t.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, fmt.Errorf("unexpected signing method: %v", t.Header["alg"])
		}
		return secret, nil
	})
	if err != nil || !token.Valid {
		return nil, ErrInvalidToken
	}

	claims, ok := token.Claims.(*Claims)
	if !ok || claims.Type != expectedType {
		return nil, ErrInvalidToken
	}

	return claims, nil
}
