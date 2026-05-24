package models

import (
	"encoding/json"
	"time"

	"github.com/google/uuid"
)

// Member is the domain model for gym members.
// PasswordHash is deliberately absent — credentials are fetched only via
// GetMemberCredentials and are never cached or serialised.
type Member struct {
	ID                 uuid.UUID  `json:"id"`
	Name               string     `json:"name"`
	Phone              string     `json:"phone"`
	Goal               *string    `json:"goal,omitempty"`
	JoinDate           time.Time  `json:"join_date"`
	Gender             string     `json:"gender"`
	CurrentWeight      *float64   `json:"current_weight,omitempty"`
	HeightCm           *float64   `json:"height_cm,omitempty"`
	DateOfBirth        *time.Time `json:"date_of_birth,omitempty"`
	Religion           *string    `json:"religion,omitempty"`
	BloodGroup         *string    `json:"blood_group,omitempty"`
	Hobbies            []string   `json:"hobbies,omitempty"`
	PresentAddress     *string    `json:"present_address,omitempty"`
	PermanentAddress   *string    `json:"permanent_address,omitempty"`
	Occupation         *string    `json:"occupation,omitempty"`
	NID                *string    `json:"nid,omitempty"`
	EmergencyPhone     *string    `json:"emergency_phone,omitempty"`
	Email              *string    `json:"email,omitempty"`
	Status             string     `json:"status"` // active | inactive | pending | rejected
	MustChangePassword bool       `json:"must_change_password"`
	CreatedAt          time.Time  `json:"created_at"`
	UpdatedAt          time.Time  `json:"updated_at"`
	BudgetLevel        *string    `json:"budget_level,omitempty"`
	IsAIAllowed        bool       `json:"is_ai_allowed"`
	IsAIFoodLogAllowed bool       `json:"is_ai_food_log_allowed"`
	ProfilePictureURL  *string          `json:"profile_picture_url,omitempty"`
	DietChartJSON      *json.RawMessage `json:"diet_chart_json,omitempty"`
	PendingDietChartJSON *json.RawMessage `json:"pending_diet_chart_json,omitempty"`
	CreatedByAdminID     *uuid.UUID       `json:"created_by_admin_id,omitempty"`
}

// Admin is the domain model for the gym owner account.
type Admin struct {
	ID                     uuid.UUID  `json:"id"`
	Name                   string     `json:"name"`
	Phone                  *string    `json:"phone,omitempty"`
	Email                  string     `json:"email"`
	CreatedAt              time.Time  `json:"created_at"`
	UpdatedAt              time.Time  `json:"updated_at"`
	Role                   string     `json:"role"`
	ParentAdminID          *uuid.UUID `json:"parent_admin_id,omitempty"`
	CreatedBySuperadminID  *uuid.UUID `json:"created_by_superadmin_id,omitempty"`
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
	Role         string // "admin" | "superadmin"
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
