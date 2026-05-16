package postgres

import (
	"context"
	"database/sql"
	"errors"
	"fmt"

	sqlcdb "github.com/asadlive84/fitness-care-bagerhat/internal/database/sqlc"
	"github.com/asadlive84/fitness-care-bagerhat/internal/models"
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
	return err
}

func (r *PlanRepo) GetByID(ctx context.Context, id uuid.UUID) (*models.PlanTemplate, error) {
	row, err := r.q.GetPlanTemplateByID(ctx, id)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, fmt.Errorf("plan not found")
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

func (r *PlanRepo) Update(ctx context.Context, p *models.PlanTemplate) error {
	_, err := r.q.UpdatePlanTemplate(ctx, sqlcdb.UpdatePlanTemplateParams{
		ID:           p.ID,
		Name:         p.Name,
		DurationDays: p.DurationDays,
		DefaultPrice: p.DefaultPrice,
	})
	if err != nil {
		return fmt.Errorf("update plan: %w", err)
	}
	return nil
}

func (r *PlanRepo) Delete(ctx context.Context, id uuid.UUID) error {
	return r.q.DeletePlanTemplate(ctx, id)
}
