package models

import (
	"time"

	"github.com/google/uuid"
)

// Member is the domain model for gym members.
// PasswordHash is deliberately absent — credentials are fetched only by the
// auth repository method (GetCredentials) and never cached or serialised.
type Member struct {
	ID                 uuid.UUID `json:"id"`
	Name               string    `json:"name"`
	Phone              string    `json:"phone"`
	Goal               *string   `json:"goal,omitempty"`
	JoinDate           time.Time `json:"join_date"`
	CurrentWeight      *float64  `json:"current_weight,omitempty"`
	Status             string    `json:"status"` // active | inactive
	MustChangePassword bool      `json:"must_change_password"`
	CreatedAt          time.Time `json:"created_at"`
	UpdatedAt          time.Time `json:"updated_at"`
}

// Admin is the domain model for the gym owner account.
type Admin struct {
	ID        uuid.UUID `json:"id"`
	Name      string    `json:"name"`
	Phone     *string   `json:"phone,omitempty"`
	Email     string    `json:"email"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

// MemberCredentials holds the data needed to verify a login attempt.
// It is never cached and never returned to the HTTP layer.
type MemberCredentials struct {
	MemberID           uuid.UUID
	PasswordHash       string
	Status             string
	MustChangePassword bool
}

// AdminCredentials holds login data for admin auth.
type AdminCredentials struct {
	AdminID      uuid.UUID
	PasswordHash string
}

// MemberFilter holds optional params for the paginated member list.
type MemberFilter struct {
	Status *string // nil = all statuses; "active" | "inactive"
	Search *string // nil = no text filter; matches name or phone prefix
	Page   int     // 1-based; 0 treated as 1
	Limit  int     // 0 defaults to a reasonable page size in the repository
}

// Offset returns the SQL OFFSET for the current page.
func (f MemberFilter) Offset() int {
	p := f.Page
	if p < 1 {
		p = 1
	}
	return (p - 1) * f.Limit
}
