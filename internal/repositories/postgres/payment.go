package postgres

import (
	"context"
	"database/sql"
	"fmt"
	"time"

	sqlcdb "github.com/asadlive84/fitness-care-bagerhat/internal/database/sqlc"
	"github.com/asadlive84/fitness-care-bagerhat/internal/models"
	"github.com/google/uuid"
)

// PaymentRepo is a pure Postgres implementation — payments are never cached.
type PaymentRepo struct {
	q *sqlcdb.Queries
}

func NewPaymentRepo(db sqlcdb.DBTX) *PaymentRepo {
	return &PaymentRepo{q: sqlcdb.New(db)}
}

func (r *PaymentRepo) Create(ctx context.Context, p *models.Payment) error {
	_, err := r.q.CreatePayment(ctx, sqlcdb.CreatePaymentParams{
		ID:                p.ID,
		MemberID:          p.MemberID,
		SubscriptionID:    p.SubscriptionID,
		Amount:            p.Amount,
		Method:            p.Method,
		PaidAt:            p.PaidAt,
		RecordedByAdminID: p.RecordedByAdminID,
	})
	return mapErr(err)
}

func (r *PaymentRepo) ListByMember(ctx context.Context, memberID uuid.UUID, filter models.PaymentFilter) ([]*models.Payment, error) {
	rows, err := r.q.ListPaymentsByMember(ctx, sqlcdb.ListPaymentsByMemberParams{
		MemberID: memberID,
		FromTime: nullTime(filter.From),
		ToTime:   nullTime(filter.To),
	})
	if err != nil {
		return nil, fmt.Errorf("list payments: %w", err)
	}
	payments := make([]*models.Payment, len(rows))
	for i, row := range rows {
		payments[i] = mapPayment(row)
	}
	return payments, nil
}

func (r *PaymentRepo) GetSummaryByMonth(ctx context.Context, month time.Time) (*models.PaymentSummary, error) {
	row, err := r.q.GetPaymentSummaryByMonth(ctx, month)
	if err != nil {
		return nil, fmt.Errorf("payment summary: %w", err)
	}
	return &models.PaymentSummary{
		TotalAmount:  row.TotalAmount,
		PaymentCount: row.PaymentCount,
		Month:        month.Format("2006-01"),
	}, nil
}

// ── helpers ───────────────────────────────────────────────────────────────────

func mapPayment(row sqlcdb.Payment) *models.Payment {
	return &models.Payment{
		ID:                row.ID,
		MemberID:          row.MemberID,
		SubscriptionID:    row.SubscriptionID,
		Amount:            row.Amount,
		Method:            row.Method,
		PaidAt:            row.PaidAt,
		RecordedByAdminID: row.RecordedByAdminID,
		CreatedAt:         row.CreatedAt,
	}
}

func nullTime(t *time.Time) sql.NullTime {
	if t == nil {
		return sql.NullTime{}
	}
	return sql.NullTime{Time: *t, Valid: true}
}
