package models

import (
	"time"

	"github.com/google/uuid"
)

// Subscription links a member to a plan for a date range.
type Subscription struct {
	ID                  uuid.UUID  `json:"id"`
	MemberID            uuid.UUID  `json:"member_id"`
	PlanTemplateID      uuid.UUID  `json:"plan_template_id"`
	StartDate           time.Time  `json:"start_date"`
	EndDate             time.Time  `json:"end_date"`
	FinalPrice          float64    `json:"final_price"`
	Note                *string    `json:"note,omitempty"`
	Status              string     `json:"status"` // active | expired | replaced
	BillingType         string     `json:"billing_type"`                     // prepaid | postpaid
	PrepaidDueDate      *time.Time `json:"prepaid_due_date,omitempty"`
	PostpaidGraceBefore int        `json:"postpaid_grace_before"`
	PostpaidGraceAfter  int        `json:"postpaid_grace_after"`
	CreatedAt           time.Time  `json:"created_at"`
}

// EnrichedSubscription joins subscription data with plan info and payment aggregation.
// Used by the admin GetMember and member GetActiveSubscription endpoints.
type EnrichedSubscription struct {
	ID                  uuid.UUID  `json:"id"`
	MemberID            uuid.UUID  `json:"member_id"`
	PlanTemplateID      uuid.UUID  `json:"plan_template_id"`
	PlanName            string     `json:"plan_name"`
	PlanPrice           float64    `json:"plan_price"`
	StartDate           time.Time  `json:"start_date"`
	EndDate             time.Time  `json:"end_date"`
	FinalPrice          float64    `json:"final_price"`
	Note                *string    `json:"note,omitempty"`
	Status              string     `json:"status"`
	MoneyPaid           float64    `json:"money_paid"`
	MoneyLeft           float64    `json:"money_left"`
	BillingType         string     `json:"billing_type"`
	PrepaidDueDate      *time.Time `json:"prepaid_due_date,omitempty"`
	PostpaidGraceBefore int        `json:"postpaid_grace_before"`
	PostpaidGraceAfter  int        `json:"postpaid_grace_after"`
	BillingStatus       string     `json:"billing_status"`                  // computed
	PaymentWindowStart  *time.Time `json:"payment_window_start,omitempty"`  // postpaid only
	PaymentWindowEnd    *time.Time `json:"payment_window_end,omitempty"`    // postpaid only
	DaysUntilDue        *int       `json:"days_until_due,omitempty"`        // positive=days left, negative=days overdue
	CreatedAt           time.Time  `json:"created_at"`
}

// ComputeBillingStatus derives BillingStatus, PaymentWindowStart, PaymentWindowEnd,
// and DaysUntilDue from the subscription fields. Call this after scanning from DB.
func (e *EnrichedSubscription) ComputeBillingStatus(now time.Time) {
	if e.MoneyLeft <= 0 {
		e.BillingStatus = "paid"
		e.DaysUntilDue = nil
		return
	}

	if e.BillingType == "prepaid" {
		var due time.Time
		if e.PrepaidDueDate == nil {
			due = e.StartDate.AddDate(0, 0, 5) // Fallback for legacy data
		} else {
			due = *e.PrepaidDueDate
		}
		
		// If due date is 14:00 today, and now is 15:00 today, Sub().Hours()/24 might be 0 but it's overdue
		// To be strictly correct by calendar days, we can truncate to 24h, but Sub().Hours()/24 is fine for approximation.
		// However, it's safer to use calendar day difference:
		nowDate := time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, now.Location())
		dueDate := time.Date(due.Year(), due.Month(), due.Day(), 0, 0, 0, 0, due.Location())
		days := int(dueDate.Sub(nowDate).Hours() / 24)
		
		e.DaysUntilDue = &days
		if days >= 0 {
			e.BillingStatus = "prepaid_due"
		} else {
			e.BillingStatus = "prepaid_overdue"
		}
		return
	}

	// postpaid
	windowStart := e.EndDate.AddDate(0, 0, -e.PostpaidGraceBefore)
	windowEnd := e.EndDate.AddDate(0, 0, e.PostpaidGraceAfter)
	e.PaymentWindowStart = &windowStart
	e.PaymentWindowEnd = &windowEnd

	if now.Before(windowStart) {
		e.BillingStatus = "postpaid_not_due_yet"
		days := int(windowStart.Sub(now).Hours() / 24)
		e.DaysUntilDue = &days
	} else if now.After(windowEnd) {
		e.BillingStatus = "postpaid_overdue"
		days := -int(now.Sub(windowEnd).Hours() / 24)
		e.DaysUntilDue = &days
	} else {
		e.BillingStatus = "postpaid_window_open"
		days := int(windowEnd.Sub(now).Hours() / 24)
		e.DaysUntilDue = &days
	}
}

// ExpiringSubscription enriches a subscription with member info for the scheduler.
type ExpiringSubscription struct {
	Subscription
	MemberName       string     `json:"member_name"`
	CreatedByAdminID *uuid.UUID `json:"created_by_admin_id,omitempty"`
}
