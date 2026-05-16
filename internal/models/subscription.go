package models

import (
	"time"

	"github.com/google/uuid"
)

// Subscription links a member to a plan for a date range.
type Subscription struct {
	ID             uuid.UUID `json:"id"`
	MemberID       uuid.UUID `json:"member_id"`
	PlanTemplateID uuid.UUID `json:"plan_template_id"`
	StartDate      time.Time `json:"start_date"`
	EndDate        time.Time `json:"end_date"`
	FinalPrice     float64   `json:"final_price"`
	Note           *string   `json:"note,omitempty"`
	Status         string    `json:"status"` // active | expired | replaced
	CreatedAt      time.Time `json:"created_at"`
}

// ExpiringSubscription enriches a subscription with member info for the scheduler.
type ExpiringSubscription struct {
	Subscription
	MemberName string `json:"member_name"`
}
