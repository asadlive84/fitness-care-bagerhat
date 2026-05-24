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
	BillingType  string // prepaid | postpaid; defaults to "prepaid" if empty
}

// UpdatePlanRequest carries validated fields for a plan update.
type UpdatePlanRequest struct {
	Name         string
	DurationDays int32
	DefaultPrice float64
	BillingType  string // prepaid | postpaid; defaults to "prepaid" if empty
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
	billingType := req.BillingType
	if billingType == "" {
		billingType = "prepaid"
	}
	plan := &models.PlanTemplate{
		ID:           uuid.New(),
		Name:         req.Name,
		DurationDays: req.DurationDays,
		DefaultPrice: req.DefaultPrice,
		BillingType:  billingType,
		IsPublic:     true, // visible on public landing page by default
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

// ListPublicPlans returns only plans flagged is_public=true — used by the public landing page.
func (s *PlanService) ListPublicPlans(ctx context.Context) ([]*models.PlanTemplate, error) {
	all, err := s.plans.List(ctx)
	if err != nil {
		return nil, fmt.Errorf("list public plans: %w", err)
	}
	result := make([]*models.PlanTemplate, 0, len(all))
	for _, p := range all {
		if p.IsPublic {
			result = append(result, p)
		}
	}
	return result, nil
}

// SetPlanVisibility toggles the is_public flag for a plan.
func (s *PlanService) SetPlanVisibility(ctx context.Context, id uuid.UUID, isPublic bool) (*models.PlanTemplate, error) {
	if err := s.plans.SetPublic(ctx, id, isPublic); err != nil {
		if errors.Is(err, repositories.ErrNotFound) {
			return nil, ErrNotFound
		}
		return nil, fmt.Errorf("set plan visibility: %w", err)
	}
	plan, err := s.plans.GetByID(ctx, id)
	if err != nil {
		return nil, fmt.Errorf("fetch plan after visibility update: %w", err)
	}
	return plan, nil
}

// ListPlansWithSubscribers returns plans with pro-rated financials for the given
// period (or lifetime when filter is zero). Never cached.
func (s *PlanService) ListPlansWithSubscribers(ctx context.Context, filter models.PlanListFilter) (*models.PlansListResponse, error) {
	resp, err := s.plans.ListWithSubscribers(ctx, filter)
	if err != nil {
		return nil, fmt.Errorf("list plans with subscribers: %w", err)
	}
	return resp, nil
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
	if req.BillingType != "" {
		plan.BillingType = req.BillingType
	}

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
