package cached

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"time"
	// time used by UpdateActive parameter

	"github.com/asadlive84/fitness-care-bagerhat/internal/cache"
	"github.com/asadlive84/fitness-care-bagerhat/internal/models"
	"github.com/asadlive84/fitness-care-bagerhat/internal/repositories"
	"github.com/google/uuid"
)

const activeSubTTL = time.Hour

// SubscriptionRepo wraps a SubscriptionRepository, caching the active subscription
// per member under "member:{id}:subscription:active".
type SubscriptionRepo struct {
	db    repositories.SubscriptionRepository
	cache *cache.Client
	log   *slog.Logger
}

func NewSubscriptionRepo(db repositories.SubscriptionRepository, c *cache.Client, log *slog.Logger) *SubscriptionRepo {
	return &SubscriptionRepo{db: db, cache: c, log: log}
}

// GetActiveByMemberID implements cache-aside for member:{id}:subscription:active.
func (r *SubscriptionRepo) GetActiveByMemberID(ctx context.Context, memberID uuid.UUID) (*models.Subscription, error) {
	key := activeSubKey(memberID)

	var s models.Subscription
	if err := r.cache.GetJSON(ctx, key, &s); err == nil {
		return &s, nil // cache HIT
	} else if !errors.Is(err, cache.ErrCacheMiss) {
		r.log.WarnContext(ctx, "cache get active subscription", "error", err, "key", key)
	}

	sub, err := r.db.GetActiveByMemberID(ctx, memberID)
	if err != nil {
		return nil, err
	}
	if sub == nil {
		return nil, nil // no active sub — don't cache nil
	}

	if setErr := r.cache.SetJSON(ctx, key, sub, activeSubTTL); setErr != nil {
		r.log.WarnContext(ctx, "cache set active subscription", "error", setErr, "key", key)
	}
	return sub, nil
}

// Create writes to DB then invalidates the cached active subscription.
func (r *SubscriptionRepo) Create(ctx context.Context, s *models.Subscription) error {
	if err := r.db.Create(ctx, s); err != nil {
		return err
	}
	r.invalidateActiveSub(ctx, s.MemberID)
	return nil
}

// ListByMemberID is not cached — history queries bypass the cache.
func (r *SubscriptionRepo) ListByMemberID(ctx context.Context, memberID uuid.UUID) ([]*models.Subscription, error) {
	return r.db.ListByMemberID(ctx, memberID)
}

// UpdateStatus writes to DB then invalidates the active-sub cache for the member.
func (r *SubscriptionRepo) UpdateStatus(ctx context.Context, id, memberID uuid.UUID, status string) error {
	if err := r.db.UpdateStatus(ctx, id, memberID, status); err != nil {
		return err
	}
	r.invalidateActiveSub(ctx, memberID)
	return nil
}

// ReplaceActive writes to DB then invalidates the active-sub cache.
func (r *SubscriptionRepo) ReplaceActive(ctx context.Context, memberID uuid.UUID) error {
	if err := r.db.ReplaceActive(ctx, memberID); err != nil {
		return err
	}
	r.invalidateActiveSub(ctx, memberID)
	return nil
}

// UpdateActive updates the active subscription in place then invalidates cache.
func (r *SubscriptionRepo) UpdateActive(ctx context.Context, memberID uuid.UUID, endDate time.Time, finalPrice float64, note *string) (*models.Subscription, error) {
	sub, err := r.db.UpdateActive(ctx, memberID, endDate, finalPrice, note)
	if err != nil {
		return nil, err
	}
	r.invalidateActiveSub(ctx, memberID)
	return sub, nil
}

// ListExpiring is not cached — used by scheduler, needs fresh data.
func (r *SubscriptionRepo) ListExpiring(ctx context.Context, days int) ([]*models.ExpiringSubscription, error) {
	return r.db.ListExpiring(ctx, days)
}

func (r *SubscriptionRepo) invalidateActiveSub(ctx context.Context, memberID uuid.UUID) {
	key := activeSubKey(memberID)
	if err := r.cache.Delete(ctx, key); err != nil {
		r.log.WarnContext(ctx, "cache delete active subscription", "error", err, "key", key)
	}
}

func activeSubKey(memberID uuid.UUID) string {
	return fmt.Sprintf("member:%s:subscription:active", memberID)
}
