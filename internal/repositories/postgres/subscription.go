package postgres

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"time"

	sqlcdb "github.com/asadlive84/fitness-care-bagerhat/internal/database/sqlc"
	"github.com/asadlive84/fitness-care-bagerhat/internal/models"
	"github.com/google/uuid"
)

// SubscriptionRepo is a pure Postgres implementation for subscriptions.
type SubscriptionRepo struct {
	q *sqlcdb.Queries
}

func NewSubscriptionRepo(db sqlcdb.DBTX) *SubscriptionRepo {
	return &SubscriptionRepo{q: sqlcdb.New(db)}
}

func (r *SubscriptionRepo) Create(ctx context.Context, s *models.Subscription) error {
	_, err := r.q.CreateSubscription(ctx, sqlcdb.CreateSubscriptionParams{
		ID:             s.ID,
		MemberID:       s.MemberID,
		PlanTemplateID: s.PlanTemplateID,
		StartDate:      s.StartDate,
		EndDate:        s.EndDate,
		FinalPrice:     s.FinalPrice,
		Note:           nullString(s.Note),
		Status:         s.Status,
	})
	return err
}

func (r *SubscriptionRepo) GetActiveByMemberID(ctx context.Context, memberID uuid.UUID) (*models.Subscription, error) {
	row, err := r.q.GetActiveSubscriptionByMemberID(ctx, memberID)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, nil // no active subscription is a valid state
	}
	if err != nil {
		return nil, fmt.Errorf("get active subscription: %w", err)
	}
	return mapSubscription(row), nil
}

func (r *SubscriptionRepo) ListByMemberID(ctx context.Context, memberID uuid.UUID) ([]*models.Subscription, error) {
	rows, err := r.q.ListSubscriptionsByMemberID(ctx, memberID)
	if err != nil {
		return nil, fmt.Errorf("list subscriptions: %w", err)
	}
	subs := make([]*models.Subscription, len(rows))
	for i, row := range rows {
		subs[i] = mapSubscription(row)
	}
	return subs, nil
}

func (r *SubscriptionRepo) UpdateStatus(ctx context.Context, id uuid.UUID, _ uuid.UUID, status string) error {
	return r.q.UpdateSubscriptionStatus(ctx, sqlcdb.UpdateSubscriptionStatusParams{
		ID:     id,
		Status: status,
	})
}

func (r *SubscriptionRepo) UpdateActive(ctx context.Context, memberID uuid.UUID, endDate time.Time, finalPrice float64, note *string) (*models.Subscription, error) {
	row, err := r.q.UpdateActiveSubscription(ctx, sqlcdb.UpdateActiveSubscriptionParams{
		MemberID:   memberID,
		EndDate:    endDate,
		FinalPrice: finalPrice,
		Note:       nullString(note),
	})
	if err != nil {
		return nil, fmt.Errorf("update active subscription: %w", mapErr(err))
	}
	return mapSubscription(row), nil
}

func (r *SubscriptionRepo) ReplaceActive(ctx context.Context, memberID uuid.UUID) error {
	return r.q.ReplaceActiveSubscriptions(ctx, memberID)
}

func (r *SubscriptionRepo) ListExpiring(ctx context.Context, days int) ([]*models.ExpiringSubscription, error) {
	rows, err := r.q.ListExpiringSubscriptions(ctx, int32(days))
	if err != nil {
		return nil, fmt.Errorf("list expiring subscriptions: %w", err)
	}
	result := make([]*models.ExpiringSubscription, len(rows))
	for i, row := range rows {
		result[i] = &models.ExpiringSubscription{
			Subscription: *mapSubscription(sqlcdb.Subscription{
				ID:             row.ID,
				MemberID:       row.MemberID,
				PlanTemplateID: row.PlanTemplateID,
				StartDate:      row.StartDate,
				EndDate:        row.EndDate,
				FinalPrice:     row.FinalPrice,
				Note:           row.Note,
				Status:         row.Status,
				CreatedAt:      row.CreatedAt,
			}),
			MemberName: row.MemberName,
		}
	}
	return result, nil
}
