package postgres

import (
	"context"
	"database/sql"
	"errors"
	"fmt"

	sqlcdb "github.com/asadlive84/fitness-care-bagerhat/internal/database/sqlc"
	"github.com/asadlive84/fitness-care-bagerhat/internal/models"
	"github.com/asadlive84/fitness-care-bagerhat/internal/repositories"
	"github.com/google/uuid"
)

// PlanRepo is a pure Postgres implementation for plan_templates.
type PlanRepo struct {
	q  *sqlcdb.Queries
	db sqlcdb.DBTX // stored for the member-count LIST query
}

func NewPlanRepo(db sqlcdb.DBTX) *PlanRepo {
	return &PlanRepo{q: sqlcdb.New(db), db: db}
}

func (r *PlanRepo) Create(ctx context.Context, p *models.PlanTemplate) error {
	_, err := r.q.CreatePlanTemplate(ctx, sqlcdb.CreatePlanTemplateParams{
		ID:           p.ID,
		Name:         p.Name,
		DurationDays: p.DurationDays,
		DefaultPrice: p.DefaultPrice,
	})
	return mapErr(err)
}

// GetByID returns a plan by primary key.
// Returns repositories.ErrNotFound when no row matches.
func (r *PlanRepo) GetByID(ctx context.Context, id uuid.UUID) (*models.PlanTemplate, error) {
	row, err := r.q.GetPlanTemplateByID(ctx, id)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, repositories.ErrNotFound
	}
	if err != nil {
		return nil, fmt.Errorf("get plan by id: %w", err)
	}
	return mapPlan(row), nil
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
// UpdatePlanTemplate uses RETURNING, so sql.ErrNoRows means no row matched —
// mapErr converts that to repositories.ErrNotFound.
func (r *PlanRepo) Update(ctx context.Context, p *models.PlanTemplate) error {
	_, err := r.q.UpdatePlanTemplate(ctx, sqlcdb.UpdatePlanTemplateParams{
		ID:           p.ID,
		Name:         p.Name,
		DurationDays: p.DurationDays,
		DefaultPrice: p.DefaultPrice,
	})
	if err != nil {
		return fmt.Errorf("update plan: %w", mapErr(err))
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
