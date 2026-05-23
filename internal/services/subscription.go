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
	PlanTemplateID      uuid.UUID
	StartDate           time.Time  // defaults to today if zero
	FinalPrice          *float64   // defaults to plan's default_price if nil
	Note                *string
	BillingType         string     // defaults to plan's billing_type if empty
	PrepaidDueDate      *time.Time
	PostpaidGraceBefore *int       // nil = use default 5
	PostpaidGraceAfter  *int       // nil = use default 5
}

// UpdateActiveRequest carries the fields that can be patched on the active sub.
type UpdateActiveRequest struct {
	StartDate           time.Time
	EndDate             time.Time
	FinalPrice          float64
	Note                *string
	BillingType         string
	PrepaidDueDate      *time.Time
	PostpaidGraceBefore *int
	PostpaidGraceAfter  *int
}

// SubscriptionService handles subscription business logic.
type SubscriptionService struct {
	subs    repositories.SubscriptionRepository
	members repositories.MemberRepository
	plans   repositories.PlanRepository
	settings *SettingService
}

// NewSubscriptionService constructs a SubscriptionService.
func NewSubscriptionService(
	subs repositories.SubscriptionRepository,
	members repositories.MemberRepository,
	plans repositories.PlanRepository,
	settings *SettingService,
) *SubscriptionService {
	return &SubscriptionService{subs: subs, members: members, plans: plans, settings: settings}
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

	// 5. Determine billing type (fallback to plan's billing_type).
	billingType := req.BillingType
	if billingType == "" {
		billingType = plan.BillingType
	}
	if billingType == "" {
		billingType = "prepaid"
	}

	// 6. Determine grace periods.
	var adminID *uuid.UUID
	if member.CreatedByAdminID != nil {
		adminID = member.CreatedByAdminID
	}
	gp := s.settings.GetGracePeriods(ctx, adminID)

	graceBefore := gp.PostpaidDays
	if req.PostpaidGraceBefore != nil {
		graceBefore = *req.PostpaidGraceBefore
	}
	graceAfter := gp.PostpaidDays
	if req.PostpaidGraceAfter != nil {
		graceAfter = *req.PostpaidGraceAfter
	}

	prepaidDueDate := req.PrepaidDueDate
	if prepaidDueDate == nil && billingType == "prepaid" {
		t := startDate.AddDate(0, 0, gp.PrepaidDays)
		prepaidDueDate = &t
	}

	// 7. Replace any current active subscription.
	if err := s.subs.ReplaceActive(ctx, memberID); err != nil {
		return nil, fmt.Errorf("replace active subscription: %w", err)
	}

	// 8. Create new subscription.
	sub := &models.Subscription{
		ID:                  uuid.New(),
		MemberID:            memberID,
		PlanTemplateID:      req.PlanTemplateID,
		StartDate:           startDate,
		EndDate:             endDate,
		FinalPrice:          finalPrice,
		Note:                req.Note,
		Status:              "active",
		BillingType:         billingType,
		PrepaidDueDate:      prepaidDueDate,
		PostpaidGraceBefore: graceBefore,
		PostpaidGraceAfter:  graceAfter,
		CreatedAt:           time.Now(),
	}
	if err := s.subs.Create(ctx, sub); err != nil {
		return nil, fmt.Errorf("create subscription: %w", err)
	}
	return sub, nil
}

// GetActiveSubscriptionEnriched returns the active subscription joined with plan
// name, plan price, and payment totals. Returns nil, nil when no active sub exists.
func (s *SubscriptionService) GetActiveSubscriptionEnriched(ctx context.Context, memberID uuid.UUID) (*models.EnrichedSubscription, error) {
	sub, err := s.subs.GetActiveEnrichedByMemberID(ctx, memberID)
	if err != nil {
		return nil, fmt.Errorf("get enriched active subscription: %w", err)
	}
	return sub, nil // nil means no active subscription
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

// UpdateActive patches price, end_date, note, and billing fields on the current active sub.
func (s *SubscriptionService) UpdateActive(ctx context.Context, memberID uuid.UUID, req UpdateActiveRequest) (*models.Subscription, error) {
	member, err := s.members.GetByID(ctx, memberID)
	if err != nil {
		if errors.Is(err, repositories.ErrNotFound) {
			return nil, ErrNotFound
		}
		return nil, fmt.Errorf("get member: %w", err)
	}

	billingType := req.BillingType
	if billingType == "" {
		billingType = "prepaid"
	}
	var adminID *uuid.UUID
	if member.CreatedByAdminID != nil {
		adminID = member.CreatedByAdminID
	}
	gp := s.settings.GetGracePeriods(ctx, adminID)

	graceBefore := gp.PostpaidDays
	if req.PostpaidGraceBefore != nil {
		graceBefore = *req.PostpaidGraceBefore
	}
	graceAfter := gp.PostpaidDays
	if req.PostpaidGraceAfter != nil {
		graceAfter = *req.PostpaidGraceAfter
	}

	prepaidDueDate := req.PrepaidDueDate
	if prepaidDueDate == nil && billingType == "prepaid" {
		t := req.StartDate.AddDate(0, 0, gp.PrepaidDays)
		prepaidDueDate = &t
	}

	sub, err := s.subs.UpdateActive(ctx, memberID, req.StartDate, req.EndDate, req.FinalPrice, req.Note, billingType, prepaidDueDate, graceBefore, graceAfter)
	if err != nil {
		if errors.Is(err, repositories.ErrNotFound) {
			return nil, fmt.Errorf("%w: no active subscription for this member", ErrNotFound)
		}
		return nil, fmt.Errorf("update active subscription: %w", err)
	}
	return sub, nil
}
