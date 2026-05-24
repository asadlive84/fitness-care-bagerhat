package cached

import (
	"context"
	"errors"
	"log/slog"
	"time"

	"github.com/asadlive84/fitness-care-bagerhat/internal/cache"
	"github.com/asadlive84/fitness-care-bagerhat/internal/models"
	"github.com/asadlive84/fitness-care-bagerhat/internal/repositories"
	"github.com/google/uuid"
)

const (
	plansCacheKey = "plans:all"
	plansTTL      = 24 * time.Hour
)

// PlanRepo wraps a PlanRepository, caching the full plan list under "plans:all".
type PlanRepo struct {
	db    repositories.PlanRepository
	cache *cache.Client
	log   *slog.Logger
}

func NewPlanRepo(db repositories.PlanRepository, c *cache.Client, log *slog.Logger) *PlanRepo {
	return &PlanRepo{db: db, cache: c, log: log}
}

// List implements cache-aside for the full plan list (plans:all).
func (r *PlanRepo) List(ctx context.Context) ([]*models.PlanTemplate, error) {
	var plans []*models.PlanTemplate
	if err := r.cache.GetJSON(ctx, plansCacheKey, &plans); err == nil {
		return plans, nil // cache HIT
	} else if !errors.Is(err, cache.ErrCacheMiss) {
		r.log.WarnContext(ctx, "cache get plans", "error", err)
	}

	plans, err := r.db.List(ctx)
	if err != nil {
		return nil, err
	}

	if setErr := r.cache.SetJSON(ctx, plansCacheKey, plans, plansTTL); setErr != nil {
		r.log.WarnContext(ctx, "cache set plans", "error", setErr)
	}
	return plans, nil
}

// GetByID goes directly to DB — the full list cache handles the common read
// case, and single-plan reads are rare (admin edit flow only).
func (r *PlanRepo) GetByID(ctx context.Context, id uuid.UUID) (*models.PlanTemplate, error) {
	return r.db.GetByID(ctx, id)
}

// Create writes to DB then busts the list cache.
func (r *PlanRepo) Create(ctx context.Context, p *models.PlanTemplate) error {
	if err := r.db.Create(ctx, p); err != nil {
		return err
	}
	r.invalidatePlans(ctx)
	return nil
}

// Update writes to DB then busts the list cache.
func (r *PlanRepo) Update(ctx context.Context, p *models.PlanTemplate) error {
	if err := r.db.Update(ctx, p); err != nil {
		return err
	}
	r.invalidatePlans(ctx)
	return nil
}

// Delete writes to DB then busts the list cache.
func (r *PlanRepo) Delete(ctx context.Context, id uuid.UUID) error {
	if err := r.db.Delete(ctx, id); err != nil {
		return err
	}
	r.invalidatePlans(ctx)
	return nil
}

// ListWithSubscribers bypasses the cache — financial data must always be live.
func (r *PlanRepo) ListWithSubscribers(ctx context.Context, filter models.PlanListFilter) (*models.PlansListResponse, error) {
	return r.db.ListWithSubscribers(ctx, filter)
}

// SetPublic writes to DB then busts the list cache.
func (r *PlanRepo) SetPublic(ctx context.Context, id uuid.UUID, isPublic bool) error {
	if err := r.db.SetPublic(ctx, id, isPublic); err != nil {
		return err
	}
	r.invalidatePlans(ctx)
	return nil
}

func (r *PlanRepo) invalidatePlans(ctx context.Context) {
	if err := r.cache.Delete(ctx, plansCacheKey); err != nil {
		r.log.WarnContext(ctx, "cache delete plans", "error", err)
	}
}
