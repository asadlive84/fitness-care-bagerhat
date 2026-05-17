package models

import (
	"time"

	"github.com/google/uuid"
)

// PlanTemplate is a reusable gym membership plan definition.
type PlanTemplate struct {
	ID           uuid.UUID `json:"id"`
	Name         string    `json:"name"`
	DurationDays int32     `json:"duration_days"`
	DefaultPrice float64   `json:"default_price"`
	BillingType  string    `json:"billing_type"` // prepaid | postpaid
	CreatedAt    time.Time `json:"created_at"`
	UpdatedAt    time.Time `json:"updated_at"`
	MemberCount  int       `json:"member_count"`
}

// PlanSubscriber is a single active subscriber nested inside a plan listing.
type PlanSubscriber struct {
	MemberID              uuid.UUID `json:"member_id"`
	MemberName            string    `json:"member_name"`
	Phone                 string    `json:"phone"`
	SubscriptionPrice     float64   `json:"subscription_price"`
	SubscriptionStartDate time.Time `json:"subscription_start_date"`
	SubscriptionEndDate   time.Time `json:"subscription_end_date"`
	MoneyPaid             float64   `json:"money_paid"`
	MoneyLeft             float64   `json:"money_left"`
}

// PlanWithSubscribers extends PlanTemplate with active subscriber financial details.
type PlanWithSubscribers struct {
	PlanTemplate
	Subscribers []PlanSubscriber `json:"subscribers"`
}
