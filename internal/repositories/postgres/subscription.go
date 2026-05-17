package postgres

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"time"

	sqlcdb "github.com/asadlive84/fitness-care-bagerhat/internal/database/sqlc"
	"github.com/asadlive84/fitness-care-bagerhat/internal/models"
	"github.com/google/uuid"
)

// SubscriptionRepo is a pure Postgres implementation for subscriptions.
type SubscriptionRepo struct {
	q  *sqlcdb.Queries
	db sqlcdb.DBTX
}

func NewSubscriptionRepo(db sqlcdb.DBTX) *SubscriptionRepo {
	return &SubscriptionRepo{q: sqlcdb.New(db), db: db}
}

func (r *SubscriptionRepo) Create(ctx context.Context, s *models.Subscription) error {
	const query = `
		INSERT INTO subscriptions (
			id, member_id, plan_template_id, start_date, end_date,
			final_price, note, status,
			billing_type, prepaid_due_date, postpaid_grace_before, postpaid_grace_after
		) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)`
	var prepaidDueDate *time.Time
	if s.PrepaidDueDate != nil {
		prepaidDueDate = s.PrepaidDueDate
	}
	_, err := r.db.ExecContext(ctx, query,
		s.ID, s.MemberID, s.PlanTemplateID, s.StartDate, s.EndDate,
		s.FinalPrice, nullString(s.Note), s.Status,
		s.BillingType, prepaidDueDate, s.PostpaidGraceBefore, s.PostpaidGraceAfter,
	)
	return err
}

func (r *SubscriptionRepo) GetActiveEnrichedByMemberID(ctx context.Context, memberID uuid.UUID) (*models.EnrichedSubscription, error) {
	const q = `
		SELECT
			s.id, s.member_id, s.plan_template_id,
			s.start_date, s.end_date, s.final_price,
			s.note, s.status, s.created_at,
			pt.name       AS plan_name,
			pt.default_price AS plan_price,
			COALESCE(SUM(p.amount), 0) AS money_paid,
			s.billing_type, s.prepaid_due_date,
			s.postpaid_grace_before, s.postpaid_grace_after
		FROM subscriptions s
		JOIN plan_templates pt ON pt.id = s.plan_template_id
		LEFT JOIN payments  p  ON p.subscription_id = s.id
		WHERE s.member_id = $1 AND s.status = 'active'
		GROUP BY s.id, pt.name, pt.default_price
		LIMIT 1`

	var sub models.EnrichedSubscription
	var note sql.NullString
	var prepaidDueDate sql.NullTime
	row := r.db.QueryRowContext(ctx, q, memberID)
	err := row.Scan(
		&sub.ID, &sub.MemberID, &sub.PlanTemplateID,
		&sub.StartDate, &sub.EndDate, &sub.FinalPrice,
		&note, &sub.Status, &sub.CreatedAt,
		&sub.PlanName, &sub.PlanPrice, &sub.MoneyPaid,
		&sub.BillingType, &prepaidDueDate,
		&sub.PostpaidGraceBefore, &sub.PostpaidGraceAfter,
	)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, nil
	}
	if err != nil {
		return nil, fmt.Errorf("get active enriched subscription: %w", err)
	}
	if note.Valid {
		sub.Note = &note.String
	}
	if prepaidDueDate.Valid {
		t := prepaidDueDate.Time
		sub.PrepaidDueDate = &t
	}
	sub.MoneyLeft = sub.FinalPrice - sub.MoneyPaid
	if sub.MoneyLeft < 0 {
		sub.MoneyLeft = 0
	}
	sub.ComputeBillingStatus(time.Now().UTC())
	return &sub, nil
}

func (r *SubscriptionRepo) GetActiveByMemberID(ctx context.Context, memberID uuid.UUID) (*models.Subscription, error) {
	const query = `
		SELECT id, member_id, plan_template_id, start_date, end_date, final_price,
		       note, status, created_at,
		       billing_type, prepaid_due_date, postpaid_grace_before, postpaid_grace_after
		FROM subscriptions
		WHERE member_id = $1
		  AND status    = 'active'
		ORDER BY created_at DESC
		LIMIT 1`
	row := r.db.QueryRowContext(ctx, query, memberID)
	sub, err := scanSubscription(row)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, nil
	}
	if err != nil {
		return nil, fmt.Errorf("get active subscription: %w", err)
	}
	return sub, nil
}

func (r *SubscriptionRepo) ListByMemberID(ctx context.Context, memberID uuid.UUID) ([]*models.Subscription, error) {
	const query = `
		SELECT id, member_id, plan_template_id, start_date, end_date, final_price,
		       note, status, created_at,
		       billing_type, prepaid_due_date, postpaid_grace_before, postpaid_grace_after
		FROM subscriptions
		WHERE member_id = $1
		ORDER BY created_at DESC`
	rows, err := r.db.QueryContext(ctx, query, memberID)
	if err != nil {
		return nil, fmt.Errorf("list subscriptions: %w", err)
	}
	defer rows.Close()

	var subs []*models.Subscription
	for rows.Next() {
		sub, err := scanSubscription(rows)
		if err != nil {
			return nil, fmt.Errorf("scan subscription row: %w", err)
		}
		subs = append(subs, sub)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("list subscriptions rows: %w", err)
	}
	return subs, nil
}

func (r *SubscriptionRepo) UpdateStatus(ctx context.Context, id uuid.UUID, _ uuid.UUID, status string) error {
	return r.q.UpdateSubscriptionStatus(ctx, sqlcdb.UpdateSubscriptionStatusParams{
		ID:     id,
		Status: status,
	})
}

func (r *SubscriptionRepo) UpdateActive(ctx context.Context, memberID uuid.UUID, startDate time.Time, endDate time.Time, finalPrice float64, note *string, billingType string, prepaidDueDate *time.Time, postpaidGraceBefore int, postpaidGraceAfter int) (*models.Subscription, error) {
	const query = `
		UPDATE subscriptions
		SET final_price           = $1,
		    start_date            = $2,
		    end_date              = $3,
		    note                  = $4,
		    billing_type          = $5,
		    prepaid_due_date      = $6,
		    postpaid_grace_before = $7,
		    postpaid_grace_after  = $8
		WHERE member_id = $9
		  AND status    = 'active'
		RETURNING id, member_id, plan_template_id, start_date, end_date, final_price,
		          note, status, created_at,
		          billing_type, prepaid_due_date, postpaid_grace_before, postpaid_grace_after`
	row := r.db.QueryRowContext(ctx, query,
		finalPrice, startDate, endDate, nullString(note),
		billingType, prepaidDueDate,
		postpaidGraceBefore, postpaidGraceAfter,
		memberID,
	)
	sub, err := scanSubscription(row)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, fmt.Errorf("update active subscription: %w", mapErr(sql.ErrNoRows))
	}
	if err != nil {
		return nil, fmt.Errorf("update active subscription: %w", mapErr(err))
	}
	return sub, nil
}

func (r *SubscriptionRepo) ReplaceActive(ctx context.Context, memberID uuid.UUID) error {
	return r.q.ReplaceActiveSubscriptions(ctx, memberID)
}

func (r *SubscriptionRepo) ListExpiring(ctx context.Context, days int) ([]*models.ExpiringSubscription, error) {
	rows, err := r.q.ListExpiringSubscriptions(ctx, int32(days))
	if err != nil {
		return nil, fmt.Errorf("list expiring subscriptions: %w", err)
	}
	result := make([]*models.ExpiringSubscription, len(rows))
	for i, row := range rows {
		result[i] = &models.ExpiringSubscription{
			Subscription: models.Subscription{
				ID:             row.ID,
				MemberID:       row.MemberID,
				PlanTemplateID: row.PlanTemplateID,
				StartDate:      row.StartDate,
				EndDate:        row.EndDate,
				FinalPrice:     row.FinalPrice,
				Status:         row.Status,
				CreatedAt:      row.CreatedAt,
				BillingType:    "prepaid", // SQLC row doesn't have billing_type; default is safe here
			},
			MemberName: row.MemberName,
		}
		if row.Note.Valid {
			s := row.Note.String
			result[i].Subscription.Note = &s
		}
	}
	return result, nil
}

// ── helpers ───────────────────────────────────────────────────────────────────

// scanner abstracts *sql.Row and *sql.Rows so scanSubscription works for both.
type scanner interface {
	Scan(dest ...any) error
}

func scanSubscription(row scanner) (*models.Subscription, error) {
	s := &models.Subscription{}
	var note sql.NullString
	var prepaidDueDate sql.NullTime
	err := row.Scan(
		&s.ID, &s.MemberID, &s.PlanTemplateID,
		&s.StartDate, &s.EndDate, &s.FinalPrice,
		&note, &s.Status, &s.CreatedAt,
		&s.BillingType, &prepaidDueDate,
		&s.PostpaidGraceBefore, &s.PostpaidGraceAfter,
	)
	if err != nil {
		return nil, err
	}
	if note.Valid {
		s.Note = &note.String
	}
	if prepaidDueDate.Valid {
		t := prepaidDueDate.Time
		s.PrepaidDueDate = &t
	}
	return s, nil
}
