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

// PlanFinancials holds collection metrics for a single plan over a given period.
//
// In lifetime mode: covers all subscription statuses, no pro-ration.
// In period mode: total_billed is pro-rated (overlap/duration × final_price);
// total_collected only counts payments whose paid_at falls inside the period.
type PlanFinancials struct {
	SubscriptionsStarted int     `json:"subscriptions_started"` // started in period (lifetime = all)
	TotalBilled          float64 `json:"total_billed"`          // pro-rated for period
	TotalCollected       float64 `json:"total_collected"`       // payments received in period
	TotalDue             float64 `json:"total_due"`             // billed − collected
}

// PlanWithSubscribers extends PlanTemplate with financials and active subscriber details.
type PlanWithSubscribers struct {
	PlanTemplate
	Financials  PlanFinancials   `json:"financials"`
	Subscribers []PlanSubscriber `json:"subscribers"` // currently active regardless of filter
}

// OverallPlanSummary is the cross-plan aggregate at the top of the list response.
type OverallPlanSummary struct {
	SubscriptionsStarted int     `json:"subscriptions_started"`
	TotalBilled          float64 `json:"total_billed"`
	TotalCollected       float64 `json:"total_collected"`
	TotalDue             float64 `json:"total_due"`
}

// AppliedFilter describes the date window that was used for the query.
type AppliedFilter struct {
	Period string  `json:"period"`          // "lifetime" | "month" | "custom"
	From   *string `json:"from,omitempty"`  // YYYY-MM-DD
	To     *string `json:"to,omitempty"`    // YYYY-MM-DD
}

// PlansListResponse is the top-level payload for GET /api/v1/admin/plans.
type PlansListResponse struct {
	Filter  AppliedFilter        `json:"filter"`
	Summary *OverallPlanSummary  `json:"summary"`
	Plans   []*PlanWithSubscribers `json:"plans"`
}

// PlanListFilter carries the parsed date window from the HTTP query params.
// Both nil → lifetime mode (no pro-ration, all-time aggregation).
type PlanListFilter struct {
	From *time.Time
	To   *time.Time
}

// IsLifetime returns true when no date constraint is set.
func (f PlanListFilter) IsLifetime() bool { return f.From == nil && f.To == nil }
