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
	q *sqlcdb.Queries
}

func NewPlanRepo(db sqlcdb.DBTX) *PlanRepo {
	return &PlanRepo{q: sqlcdb.New(db)}
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
// Returns repositories.ErrNotFound when no row matches so callers can use
// errors.Is without importing database-driver types.
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

func (r *PlanRepo) List(ctx context.Context) ([]*models.PlanTemplate, error) {
	rows, err := r.q.ListPlanTemplates(ctx)
	if err != nil {
		return nil, fmt.Errorf("list plans: %w", err)
	}
	plans := make([]*models.PlanTemplate, len(rows))
	for i, row := range rows {
		plans[i] = mapPlan(row)
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
// Returns repositories.ErrFKViolation when active subscriptions reference the
// plan; mapErr converts the raw pq FK error to the sentinel value.
func (r *PlanRepo) Delete(ctx context.Context, id uuid.UUID) error {
	if err := r.q.DeletePlanTemplate(ctx, id); err != nil {
		return mapErr(err)
	}
	return nil
}
