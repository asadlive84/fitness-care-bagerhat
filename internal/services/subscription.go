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

// AssignPlanRequest carries validated input for creating a subscription.
type AssignPlanRequest struct {
	PlanTemplateID uuid.UUID
	StartDate      time.Time  // defaults to today if zero
	FinalPrice     *float64   // defaults to plan's default_price if nil
	Note           *string
}

// UpdateActiveRequest carries the fields that can be patched on the active sub.
type UpdateActiveRequest struct {
	EndDate    time.Time
	FinalPrice float64
	Note       *string
}

// SubscriptionService handles subscription business logic.
type SubscriptionService struct {
	subs    repositories.SubscriptionRepository
	members repositories.MemberRepository
	plans   repositories.PlanRepository
}

// NewSubscriptionService constructs a SubscriptionService.
func NewSubscriptionService(
	subs repositories.SubscriptionRepository,
	members repositories.MemberRepository,
	plans repositories.PlanRepository,
) *SubscriptionService {
	return &SubscriptionService{subs: subs, members: members, plans: plans}
}

// AssignPlan assigns a new subscription to a member.
// Any existing active subscription is marked 'replaced'.
func (s *SubscriptionService) AssignPlan(ctx context.Context, memberID uuid.UUID, req AssignPlanRequest) (*models.Subscription, error) {
	// 1. Validate member is active.
	member, err := s.members.GetByID(ctx, memberID)
	if err != nil {
		if errors.Is(err, repositories.ErrNotFound) {
			return nil, ErrNotFound
		}
		return nil, fmt.Errorf("get member: %w", err)
	}
	if member.Status != "active" {
		return nil, ErrMemberInactive
	}

	// 2. Fetch plan to determine duration and default price.
	plan, err := s.plans.GetByID(ctx, req.PlanTemplateID)
	if err != nil {
		if errors.Is(err, repositories.ErrNotFound) {
			return nil, fmt.Errorf("%w: plan template not found", ErrNotFound)
		}
		return nil, fmt.Errorf("get plan: %w", err)
	}

	// 3. Calculate dates.
	startDate := req.StartDate
	if startDate.IsZero() {
		startDate = time.Now().UTC().Truncate(24 * time.Hour)
	}
	endDate := startDate.AddDate(0, 0, int(plan.DurationDays))

	// 4. Determine final price.
	finalPrice := plan.DefaultPrice
	if req.FinalPrice != nil {
		finalPrice = *req.FinalPrice
	}

	// 5. Replace any current active subscription.
	if err := s.subs.ReplaceActive(ctx, memberID); err != nil {
		return nil, fmt.Errorf("replace active subscription: %w", err)
	}

	// 6. Create new subscription.
	sub := &models.Subscription{
		ID:             uuid.New(),
		MemberID:       memberID,
		PlanTemplateID: req.PlanTemplateID,
		StartDate:      startDate,
		EndDate:        endDate,
		FinalPrice:     finalPrice,
		Note:           req.Note,
		Status:         "active",
		CreatedAt:      time.Now(),
	}
	if err := s.subs.Create(ctx, sub); err != nil {
		return nil, fmt.Errorf("create subscription: %w", err)
	}
	return sub, nil
}

// GetActiveSubscription returns the current active subscription for a member.
// Returns ErrNotFound if no active subscription exists.
func (s *SubscriptionService) GetActiveSubscription(ctx context.Context, memberID uuid.UUID) (*models.Subscription, error) {
	sub, err := s.subs.GetActiveByMemberID(ctx, memberID)
	if err != nil {
		return nil, fmt.Errorf("get active subscription: %w", err)
	}
	if sub == nil {
		return nil, ErrNotFound
	}
	return sub, nil
}

// ListSubscriptions returns all subscriptions for a member (full history).
func (s *SubscriptionService) ListSubscriptions(ctx context.Context, memberID uuid.UUID) ([]*models.Subscription, error) {
	// Verify member exists.
	if _, err := s.members.GetByID(ctx, memberID); err != nil {
		if errors.Is(err, repositories.ErrNotFound) {
			return nil, ErrNotFound
		}
		return nil, fmt.Errorf("get member: %w", err)
	}
	subs, err := s.subs.ListByMemberID(ctx, memberID)
	if err != nil {
		return nil, fmt.Errorf("list subscriptions: %w", err)
	}
	return subs, nil
}

// UpdateActive patches price, end_date, and note on the current active sub.
func (s *SubscriptionService) UpdateActive(ctx context.Context, memberID uuid.UUID, req UpdateActiveRequest) (*models.Subscription, error) {
	sub, err := s.subs.UpdateActive(ctx, memberID, req.EndDate, req.FinalPrice, req.Note)
	if err != nil {
		if errors.Is(err, repositories.ErrNotFound) {
			return nil, fmt.Errorf("%w: no active subscription for this member", ErrNotFound)
		}
		return nil, fmt.Errorf("update active subscription: %w", err)
	}
	return sub, nil
}
