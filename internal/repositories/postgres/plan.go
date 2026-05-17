package postgres

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"time"

	sqlcdb "github.com/asadlive84/fitness-care-bagerhat/internal/database/sqlc"
	"github.com/asadlive84/fitness-care-bagerhat/internal/models"
	"github.com/asadlive84/fitness-care-bagerhat/internal/repositories"
	"github.com/google/uuid"
)

// PlanRepo is a pure Postgres implementation for plan_templates.
type PlanRepo struct {
	q  *sqlcdb.Queries
	db sqlcdb.DBTX // stored for raw SQL queries
}

func NewPlanRepo(db sqlcdb.DBTX) *PlanRepo {
	return &PlanRepo{q: sqlcdb.New(db), db: db}
}

func (r *PlanRepo) Create(ctx context.Context, p *models.PlanTemplate) error {
	const query = `
		INSERT INTO plan_templates (id, name, duration_days, default_price, billing_type, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7)`
	_, err := r.db.ExecContext(ctx, query,
		p.ID, p.Name, p.DurationDays, p.DefaultPrice, p.BillingType, p.CreatedAt, p.UpdatedAt,
	)
	return mapErr(err)
}

// GetByID returns a plan by primary key.
// Returns repositories.ErrNotFound when no row matches.
func (r *PlanRepo) GetByID(ctx context.Context, id uuid.UUID) (*models.PlanTemplate, error) {
	const query = `
		SELECT id, name, duration_days, default_price, billing_type, created_at, updated_at
		FROM plan_templates
		WHERE id = $1`
	row := r.db.QueryRowContext(ctx, query, id)
	p := &models.PlanTemplate{}
	err := row.Scan(&p.ID, &p.Name, &p.DurationDays, &p.DefaultPrice, &p.BillingType, &p.CreatedAt, &p.UpdatedAt)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, repositories.ErrNotFound
	}
	if err != nil {
		return nil, fmt.Errorf("get plan by id: %w", err)
	}
	return p, nil
}

// List returns all plan templates ordered newest-first.
// Each plan includes member_count — the number of members currently holding
// an ACTIVE subscription for that plan template — computed via a single
// aggregating LEFT JOIN (no N+1 queries).
func (r *PlanRepo) List(ctx context.Context) ([]*models.PlanTemplate, error) {
	const query = `
		SELECT
			pt.id,
			pt.name,
			pt.duration_days,
			pt.default_price,
			pt.billing_type,
			pt.created_at,
			pt.updated_at,
			COUNT(s.id) FILTER (WHERE s.status = 'active') AS member_count
		FROM  plan_templates  pt
		LEFT JOIN subscriptions s ON s.plan_template_id = pt.id
		GROUP BY pt.id
		ORDER BY pt.created_at DESC`

	rows, err := r.db.QueryContext(ctx, query)
	if err != nil {
		return nil, fmt.Errorf("list plans: %w", err)
	}
	defer rows.Close()

	var plans []*models.PlanTemplate
	for rows.Next() {
		p := &models.PlanTemplate{}
		if err := rows.Scan(
			&p.ID,
			&p.Name,
			&p.DurationDays,
			&p.DefaultPrice,
			&p.BillingType,
			&p.CreatedAt,
			&p.UpdatedAt,
			&p.MemberCount,
		); err != nil {
			return nil, fmt.Errorf("scan plan row: %w", err)
		}
		plans = append(plans, p)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("list plans rows: %w", err)
	}
	return plans, nil
}

// Update saves plan changes.
func (r *PlanRepo) Update(ctx context.Context, p *models.PlanTemplate) error {
	const query = `
		UPDATE plan_templates
		SET name          = $1,
		    duration_days = $2,
		    default_price = $3,
		    billing_type  = $4,
		    updated_at    = $5
		WHERE id = $6`
	result, err := r.db.ExecContext(ctx, query,
		p.Name, p.DurationDays, p.DefaultPrice, p.BillingType, time.Now(), p.ID,
	)
	if err != nil {
		return fmt.Errorf("update plan: %w", mapErr(err))
	}
	n, err := result.RowsAffected()
	if err != nil {
		return fmt.Errorf("update plan rows affected: %w", err)
	}
	if n == 0 {
		return fmt.Errorf("update plan: %w", repositories.ErrNotFound)
	}
	return nil
}

// Delete removes a plan template.
// Returns repositories.ErrFKViolation when active subscriptions reference it.
func (r *PlanRepo) Delete(ctx context.Context, id uuid.UUID) error {
	if err := r.q.DeletePlanTemplate(ctx, id); err != nil {
		return mapErr(err)
	}
	return nil
}

// ListWithSubscribers returns all plans plus per-subscriber payment aggregation
// in a single query. Plans with no active subscribers still appear with an empty
// Subscribers slice. Results are ordered: newest plan first, members alphabetically.
func (r *PlanRepo) ListWithSubscribers(ctx context.Context) ([]*models.PlanWithSubscribers, error) {
	const query = `
		SELECT
			pt.id            AS plan_id,
			pt.name          AS plan_name,
			pt.duration_days,
			pt.default_price,
			pt.billing_type,
			pt.created_at,
			pt.updated_at,
			m.id             AS member_id,
			m.name           AS member_name,
			m.phone,
			s.id             AS subscription_id,
			s.final_price    AS subscription_price,
			s.start_date     AS subscription_start_date,
			s.end_date       AS subscription_end_date,
			COALESCE(SUM(p.amount), 0) AS money_paid
		FROM plan_templates pt
		LEFT JOIN subscriptions s
			ON s.plan_template_id = pt.id AND s.status = 'active'
		LEFT JOIN members m
			ON m.id = s.member_id
		LEFT JOIN payments p
			ON p.subscription_id = s.id
		GROUP BY
			pt.id, pt.name, pt.duration_days, pt.default_price, pt.billing_type,
			pt.created_at, pt.updated_at,
			m.id, m.name, m.phone,
			s.id, s.final_price, s.start_date, s.end_date
		ORDER BY pt.created_at DESC, m.name ASC NULLS LAST`

	rows, err := r.db.QueryContext(ctx, query)
	if err != nil {
		return nil, fmt.Errorf("list plans with subscribers: %w", err)
	}
	defer rows.Close()

	// planOrder preserves insertion order of plan IDs as we encounter them.
	planOrder := make([]uuid.UUID, 0)
	planMap := make(map[uuid.UUID]*models.PlanWithSubscribers)

	for rows.Next() {
		var (
			planID   uuid.UUID
			planName string
			dur      int32
			price    float64
			billing  string
			createdAt, updatedAt time.Time

			memberID   sql.NullString
			memberName sql.NullString
			phone      sql.NullString
			subID      sql.NullString
			subPrice   sql.NullFloat64
			subStart   sql.NullTime
			subEnd     sql.NullTime
			moneyPaid  float64
		)

		if err := rows.Scan(
			&planID, &planName, &dur, &price, &billing, &createdAt, &updatedAt,
			&memberID, &memberName, &phone,
			&subID, &subPrice, &subStart, &subEnd,
			&moneyPaid,
		); err != nil {
			return nil, fmt.Errorf("scan plan-with-subscribers row: %w", err)
		}

		// Ensure the plan entry exists in the map.
		if _, seen := planMap[planID]; !seen {
			planMap[planID] = &models.PlanWithSubscribers{
				PlanTemplate: models.PlanTemplate{
					ID:           planID,
					Name:         planName,
					DurationDays: dur,
					DefaultPrice: price,
					BillingType:  billing,
					CreatedAt:    createdAt,
					UpdatedAt:    updatedAt,
				},
				Subscribers: []models.PlanSubscriber{},
			}
			planOrder = append(planOrder, planID)
		}

		// A NULL member_id means no active subscriber for this plan row.
		if !memberID.Valid {
			continue
		}

		mID, _ := uuid.Parse(memberID.String)
		finalPrice := subPrice.Float64
		paid := moneyPaid
		left := finalPrice - paid
		if left < 0 {
			left = 0
		}

		planMap[planID].Subscribers = append(planMap[planID].Subscribers, models.PlanSubscriber{
			MemberID:              mID,
			MemberName:            memberName.String,
			Phone:                 phone.String,
			SubscriptionPrice:     finalPrice,
			SubscriptionStartDate: subStart.Time,
			SubscriptionEndDate:   subEnd.Time,
			MoneyPaid:             paid,
			MoneyLeft:             left,
		})
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("list plans with subscribers rows: %w", err)
	}

	// Build ordered result and stamp MemberCount.
	result := make([]*models.PlanWithSubscribers, 0, len(planOrder))
	for _, id := range planOrder {
		p := planMap[id]
		p.MemberCount = len(p.Subscribers)
		result = append(result, p)
	}
	return result, nil
}
