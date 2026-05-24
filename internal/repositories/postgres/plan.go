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
		INSERT INTO plan_templates (id, name, duration_days, default_price, billing_type, is_public, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`
	_, err := r.db.ExecContext(ctx, query,
		p.ID, p.Name, p.DurationDays, p.DefaultPrice, p.BillingType, p.IsPublic, p.CreatedAt, p.UpdatedAt,
	)
	return mapErr(err)
}

// GetByID returns a plan by primary key.
// Returns repositories.ErrNotFound when no row matches.
func (r *PlanRepo) GetByID(ctx context.Context, id uuid.UUID) (*models.PlanTemplate, error) {
	const query = `
		SELECT id, name, duration_days, default_price, billing_type, is_public, created_at, updated_at
		FROM plan_templates
		WHERE id = $1`
	row := r.db.QueryRowContext(ctx, query, id)
	p := &models.PlanTemplate{}
	err := row.Scan(&p.ID, &p.Name, &p.DurationDays, &p.DefaultPrice, &p.BillingType, &p.IsPublic, &p.CreatedAt, &p.UpdatedAt)
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
			pt.is_public,
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
			&p.IsPublic,
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
		    is_public     = $5,
		    updated_at    = $6
		WHERE id = $7`
	result, err := r.db.ExecContext(ctx, query,
		p.Name, p.DurationDays, p.DefaultPrice, p.BillingType, p.IsPublic, time.Now(), p.ID,
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

// SetPublic flips the is_public visibility flag for one plan.
func (r *PlanRepo) SetPublic(ctx context.Context, id uuid.UUID, isPublic bool) error {
	const query = `UPDATE plan_templates SET is_public = $1, updated_at = $2 WHERE id = $3`
	result, err := r.db.ExecContext(ctx, query, isPublic, time.Now(), id)
	if err != nil {
		return fmt.Errorf("set plan public: %w", mapErr(err))
	}
	n, err := result.RowsAffected()
	if err != nil {
		return fmt.Errorf("set plan public rows affected: %w", err)
	}
	if n == 0 {
		return repositories.ErrNotFound
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

// ListWithSubscribers returns all plans with financials and active subscriber details.
//
// Lifetime mode (filter.IsLifetime()):
//   - subscriptions_started = COUNT of all subscriptions ever sold for this plan
//   - total_billed           = SUM(final_price) across all those subscriptions
//   - total_collected        = SUM of all payments ever received for this plan
//
// Period mode (filter has From/To):
//   - subscriptions_started = COUNT of subs whose start_date falls in [from, to]
//   - total_billed           = SUM(final_price) of those same subs
//   - total_collected        = SUM of payments whose paid_at falls in [from, to]
//                             regardless of which plan or subscription they belong to
//
// No pro-ration. If a member paid ৳500 in January and ৳600 in February for a
// 4-month plan, the February report shows ৳600 collected — exactly what was
// physically received in that month.
//
// The subscribers[] slice always reflects currently active members regardless of filter.
func (r *PlanRepo) ListWithSubscribers(ctx context.Context, filter models.PlanListFilter) (*models.PlansListResponse, error) {
	planOrder, planMap, overall, err := r.fetchPlanFinancials(ctx, filter)
	if err != nil {
		return nil, err
	}
	if err := r.fetchActiveSubscribers(ctx, planMap); err != nil {
		return nil, err
	}

	plans := make([]*models.PlanWithSubscribers, 0, len(planOrder))
	for _, id := range planOrder {
		p := planMap[id]
		p.MemberCount = len(p.Subscribers)
		plans = append(plans, p)
	}

	return &models.PlansListResponse{
		Filter:  buildAppliedFilter(filter),
		Summary: &overall,
		Plans:   plans,
	}, nil
}

// fetchPlanFinancials runs the financial aggregation query (Query 1).
func (r *PlanRepo) fetchPlanFinancials(
	ctx context.Context,
	filter models.PlanListFilter,
) ([]uuid.UUID, map[uuid.UUID]*models.PlanWithSubscribers, models.OverallPlanSummary, error) {

	planOrder := make([]uuid.UUID, 0)
	planMap := make(map[uuid.UUID]*models.PlanWithSubscribers)
	var overall models.OverallPlanSummary

	var (
		query string
		args  []any
	)

	if filter.IsLifetime() {
		// ── Lifetime: simple aggregation, no pro-ration ────────────────────
		// Sub-aggregate payments first to avoid counting final_price once per
		// payment row when a subscription has multiple payment entries.
		query = `
			SELECT
				pt.id, pt.name, pt.duration_days, pt.default_price,
				pt.billing_type, pt.is_public, pt.created_at, pt.updated_at,
				COUNT(s.id)                     AS subscriptions_started,
				COALESCE(SUM(s.final_price), 0) AS total_billed,
				COALESCE(SUM(sp.sub_paid), 0)   AS total_collected
			FROM plan_templates pt
			LEFT JOIN subscriptions s ON s.plan_template_id = pt.id
			LEFT JOIN (
				SELECT subscription_id, SUM(amount) AS sub_paid
				FROM payments
				GROUP BY subscription_id
			) sp ON sp.subscription_id = s.id
			GROUP BY pt.id, pt.name, pt.duration_days, pt.default_price,
			         pt.billing_type, pt.is_public, pt.created_at, pt.updated_at
			ORDER BY pt.created_at DESC`
	} else {
		// ── Period: subscription sold + payment received in [from, to] ────
		//
		// total_billed    = price of subscriptions whose start_date is in the period.
		//                   A 4-month plan sold in Jan shows ৳4000 only in January.
		//
		// total_collected = payments physically received (paid_at) in the period.
		//                   Jan partial ৳500, Feb partial ৳600 → Feb report shows ৳600.
		//
		// The two numbers belong to different sets intentionally: billed tracks
		// what was sold this period; collected tracks what cash arrived this period.
		query = `
			SELECT
				pt.id, pt.name, pt.duration_days, pt.default_price,
				pt.billing_type, pt.is_public, pt.created_at, pt.updated_at,
				COUNT(DISTINCT s.id) FILTER (
					WHERE s.start_date BETWEEN $1 AND $2
				) AS subscriptions_started,
				COALESCE(SUM(s.final_price) FILTER (
					WHERE s.start_date BETWEEN $1 AND $2
				), 0) AS total_billed,
				COALESCE(SUM(p.amount) FILTER (
					WHERE p.paid_at >= $1::timestamptz
					  AND p.paid_at <  $2::timestamptz + INTERVAL '1 day'
				), 0) AS total_collected
			FROM plan_templates pt
			LEFT JOIN subscriptions s ON s.plan_template_id = pt.id
			LEFT JOIN payments p ON p.subscription_id = s.id
			GROUP BY pt.id, pt.name, pt.duration_days, pt.default_price,
			         pt.billing_type, pt.is_public, pt.created_at, pt.updated_at
			ORDER BY pt.created_at DESC`
		args = []any{filter.From, filter.To}
	}

	rows, err := r.db.QueryContext(ctx, query, args...)
	if err != nil {
		return nil, nil, overall, fmt.Errorf("list plan financials: %w", err)
	}
	defer rows.Close()

	for rows.Next() {
		var (
			planID    uuid.UUID
			planName  string
			dur       int32
			defPrice  float64
			billing   string
			isPublic  bool
			createdAt time.Time
			updatedAt time.Time
			started   int
			billed    float64
			collected float64
		)
		if err := rows.Scan(
			&planID, &planName, &dur, &defPrice, &billing, &isPublic, &createdAt, &updatedAt,
			&started, &billed, &collected,
		); err != nil {
			return nil, nil, overall, fmt.Errorf("scan plan financials: %w", err)
		}

		due := billed - collected
		if due < 0 {
			due = 0
		}

		planMap[planID] = &models.PlanWithSubscribers{
			PlanTemplate: models.PlanTemplate{
				ID:           planID,
				Name:         planName,
				DurationDays: dur,
				DefaultPrice: defPrice,
				BillingType:  billing,
				IsPublic:     isPublic,
				CreatedAt:    createdAt,
				UpdatedAt:    updatedAt,
			},
			Financials: models.PlanFinancials{
				SubscriptionsStarted: started,
				TotalBilled:          billed,
				TotalCollected:       collected,
				TotalDue:             due,
			},
			Subscribers: []models.PlanSubscriber{},
		}
		planOrder = append(planOrder, planID)

		overall.SubscriptionsStarted += started
		overall.TotalBilled += billed
		overall.TotalCollected += collected
		overall.TotalDue += due
	}
	if err := rows.Err(); err != nil {
		return nil, nil, overall, fmt.Errorf("list plan financials rows: %w", err)
	}
	return planOrder, planMap, overall, nil
}

// fetchActiveSubscribers runs Query 2 — always shows currently active members
// regardless of the date filter — and appends them into planMap.
func (r *PlanRepo) fetchActiveSubscribers(
	ctx context.Context,
	planMap map[uuid.UUID]*models.PlanWithSubscribers,
) error {
	const query = `
		SELECT
			s.plan_template_id,
			m.id, m.name, m.phone,
			s.final_price,
			s.start_date, s.end_date,
			COALESCE(SUM(p.amount), 0) AS money_paid
		FROM subscriptions s
		JOIN members m ON m.id = s.member_id
		LEFT JOIN payments p ON p.subscription_id = s.id
		WHERE s.status = 'active'
		GROUP BY s.plan_template_id, m.id, m.name, m.phone,
		         s.final_price, s.start_date, s.end_date
		ORDER BY m.name ASC`

	rows, err := r.db.QueryContext(ctx, query)
	if err != nil {
		return fmt.Errorf("list plan subscribers: %w", err)
	}
	defer rows.Close()

	for rows.Next() {
		var (
			planID   uuid.UUID
			memberID uuid.UUID
			mName    string
			phone    string
			subPrice float64
			subStart time.Time
			subEnd   time.Time
			paid     float64
		)
		if err := rows.Scan(
			&planID, &memberID, &mName, &phone,
			&subPrice, &subStart, &subEnd, &paid,
		); err != nil {
			return fmt.Errorf("scan plan subscriber: %w", err)
		}

		plan, ok := planMap[planID]
		if !ok {
			continue // orphaned subscription (plan deleted)
		}

		left := subPrice - paid
		if left < 0 {
			left = 0
		}

		plan.Subscribers = append(plan.Subscribers, models.PlanSubscriber{
			MemberID:              memberID,
			MemberName:            mName,
			Phone:                 phone,
			SubscriptionPrice:     subPrice,
			SubscriptionStartDate: subStart,
			SubscriptionEndDate:   subEnd,
			MoneyPaid:             paid,
			MoneyLeft:             left,
		})
	}
	return rows.Err()
}

// buildAppliedFilter converts a PlanListFilter into the human-readable
// AppliedFilter block that is included in the JSON response.
func buildAppliedFilter(f models.PlanListFilter) models.AppliedFilter {
	if f.IsLifetime() {
		return models.AppliedFilter{Period: "lifetime"}
	}
	af := models.AppliedFilter{Period: "custom"}
	if f.From != nil {
		s := f.From.Format("2006-01-02")
		af.From = &s
	}
	if f.To != nil {
		s := f.To.Format("2006-01-02")
		af.To = &s
	}
	// Detect month shorthand: from = first day, to = last day of same month.
	if f.From != nil && f.To != nil &&
		f.From.Day() == 1 && f.To.Equal(f.From.AddDate(0, 1, -1)) {
		af.Period = "month"
	}
	return af
}
