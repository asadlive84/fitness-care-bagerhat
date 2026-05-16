package models

import (
	"time"

	"github.com/google/uuid"
)

// Payment records a single payment transaction.
type Payment struct {
	ID                uuid.UUID `json:"id"`
	MemberID          uuid.UUID `json:"member_id"`
	SubscriptionID    uuid.UUID `json:"subscription_id"`
	Amount            float64   `json:"amount"`
	Method            string    `json:"method"` // Cash | bKash | Nagad | Card
	PaidAt            time.Time `json:"paid_at"`
	RecordedByAdminID uuid.UUID `json:"recorded_by_admin_id"`
	CreatedAt         time.Time `json:"created_at"`
}

// PaymentSummary is the aggregated result for a given month.
type PaymentSummary struct {
	TotalAmount  float64 `json:"total_amount"`
	PaymentCount int64   `json:"payment_count"`
	Month        string  `json:"month"` // YYYY-MM
}

// PaymentFilter holds optional date-range params for listing payments.
type PaymentFilter struct {
	From *time.Time // nil = no lower bound
	To   *time.Time // nil = no upper bound
}
