package services

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/asadlive84/fitness-care-bagerhat/internal/models"
	"github.com/asadlive84/fitness-care-bagerhat/internal/repositories"
	"github.com/google/uuid"
)

// ValidPaymentMethods is the exhaustive set accepted by the app.
var ValidPaymentMethods = map[string]bool{
	"Cash":  true,
	"bKash": true,
	"Nagad": true,
	"Card":  true,
}

// RecordPaymentRequest carries validated input for recording a payment.
type RecordPaymentRequest struct {
	MemberID       uuid.UUID
	SubscriptionID uuid.UUID
	Amount         float64
	Method         string
	PaidAt         time.Time // zero → use time.Now()
	AdminID        uuid.UUID // from JWT — who recorded this
}

// PaymentService handles payment business logic.
type PaymentService struct {
	payments repositories.PaymentRepository
	members  repositories.MemberRepository
}

// NewPaymentService constructs a PaymentService.
func NewPaymentService(
	payments repositories.PaymentRepository,
	members repositories.MemberRepository,
) *PaymentService {
	return &PaymentService{payments: payments, members: members}
}

// RecordPayment validates and persists a new payment entry.
func (s *PaymentService) RecordPayment(ctx context.Context, req RecordPaymentRequest) (*models.Payment, error) {
	// Validate member exists.
	if _, err := s.members.GetByID(ctx, req.MemberID); err != nil {
		if errors.Is(err, repositories.ErrNotFound) {
			return nil, fmt.Errorf("%w: member not found", ErrNotFound)
		}
		return nil, fmt.Errorf("get member: %w", err)
	}

	paidAt := req.PaidAt
	if paidAt.IsZero() {
		paidAt = time.Now()
	}

	payment := &models.Payment{
		ID:                uuid.New(),
		MemberID:          req.MemberID,
		SubscriptionID:    req.SubscriptionID,
		Amount:            req.Amount,
		Method:            req.Method,
		PaidAt:            paidAt,
		RecordedByAdminID: req.AdminID,
		CreatedAt:         time.Now(),
	}

	if err := s.payments.Create(ctx, payment); err != nil {
		if errors.Is(err, repositories.ErrFKViolation) {
			// subscription_id or member_id FK constraint violated
			return nil, fmt.Errorf("%w: subscription not found or does not belong to member", ErrNotFound)
		}
		return nil, fmt.Errorf("record payment: %w", err)
	}

	return payment, nil
}

// ListMemberPayments returns payments for a member with an optional date-range filter.
func (s *PaymentService) ListMemberPayments(ctx context.Context, memberID uuid.UUID, filter models.PaymentFilter) ([]*models.Payment, error) {
	// Confirm member exists (gives a 404 rather than empty list on bad ID).
	if _, err := s.members.GetByID(ctx, memberID); err != nil {
		if errors.Is(err, repositories.ErrNotFound) {
			return nil, ErrNotFound
		}
		return nil, fmt.Errorf("get member: %w", err)
	}

	payments, err := s.payments.ListByMember(ctx, memberID, filter)
	if err != nil {
		return nil, fmt.Errorf("list payments: %w", err)
	}
	return payments, nil
}

// GetMonthlySummary returns total revenue and payment count for a given month.
func (s *PaymentService) GetMonthlySummary(ctx context.Context, month time.Time) (*models.PaymentSummary, error) {
	summary, err := s.payments.GetSummaryByMonth(ctx, month)
	if err != nil {
		return nil, fmt.Errorf("get payment summary: %w", err)
	}
	return summary, nil
}
