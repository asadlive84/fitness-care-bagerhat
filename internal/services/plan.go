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

// CreatePlanRequest carries validated fields for a new plan template.
type CreatePlanRequest struct {
	Name         string
	DurationDays int32
	DefaultPrice float64
}

// UpdatePlanRequest carries validated fields for a plan update.
type UpdatePlanRequest struct {
	Name         string
	DurationDays int32
	DefaultPrice float64
}

// PlanService handles plan-template business logic.
type PlanService struct {
	plans repositories.PlanRepository
}

// NewPlanService constructs a PlanService.
func NewPlanService(plans repositories.PlanRepository) *PlanService {
	return &PlanService{plans: plans}
}

// CreatePlan creates a new plan template.
func (s *PlanService) CreatePlan(ctx context.Context, req CreatePlanRequest) (*models.PlanTemplate, error) {
	plan := &models.PlanTemplate{
		ID:           uuid.New(),
		Name:         req.Name,
		DurationDays: req.DurationDays,
		DefaultPrice: req.DefaultPrice,
		CreatedAt:    time.Now(),
		UpdatedAt:    time.Now(),
	}
	if err := s.plans.Create(ctx, plan); err != nil {
		return nil, fmt.Errorf("create plan: %w", err)
	}
	return plan, nil
}

// ListPlans returns all plan templates (served from cache when warm).
func (s *PlanService) ListPlans(ctx context.Context) ([]*models.PlanTemplate, error) {
	plans, err := s.plans.List(ctx)
	if err != nil {
		return nil, fmt.Errorf("list plans: %w", err)
	}
	return plans, nil
}

// GetPlan returns a single plan template.
func (s *PlanService) GetPlan(ctx context.Context, id uuid.UUID) (*models.PlanTemplate, error) {
	plan, err := s.plans.GetByID(ctx, id)
	if err != nil {
		if errors.Is(err, repositories.ErrNotFound) {
			return nil, ErrNotFound
		}
		return nil, fmt.Errorf("get plan: %w", err)
	}
	return plan, nil
}

// UpdatePlan saves plan changes (busts the plans:all cache).
func (s *PlanService) UpdatePlan(ctx context.Context, id uuid.UUID, req UpdatePlanRequest) (*models.PlanTemplate, error) {
	plan, err := s.plans.GetByID(ctx, id)
	if err != nil {
		if errors.Is(err, repositories.ErrNotFound) {
			return nil, ErrNotFound
		}
		return nil, fmt.Errorf("fetch plan for update: %w", err)
	}

	plan.Name = req.Name
	plan.DurationDays = req.DurationDays
	plan.DefaultPrice = req.DefaultPrice

	if err := s.plans.Update(ctx, plan); err != nil {
		return nil, fmt.Errorf("update plan: %w", err)
	}
	return plan, nil
}

// DeletePlan removes a plan template. Returns ErrConflict if active subscriptions
// reference this plan (PostgreSQL FK constraint prevents deletion).
func (s *PlanService) DeletePlan(ctx context.Context, id uuid.UUID) error {
	if err := s.plans.Delete(ctx, id); err != nil {
		if errors.Is(err, repositories.ErrFKViolation) {
			return fmt.Errorf("%w: plan has active subscriptions and cannot be deleted", ErrConflict)
		}
		if errors.Is(err, repositories.ErrNotFound) {
			return ErrNotFound
		}
		return fmt.Errorf("delete plan: %w", err)
	}
	return nil
}
