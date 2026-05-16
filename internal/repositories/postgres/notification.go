package postgres

import (
	"context"
	"fmt"
	"time"

	sqlcdb "github.com/asadlive84/fitness-care-bagerhat/internal/database/sqlc"
	"github.com/asadlive84/fitness-care-bagerhat/internal/models"
	"github.com/google/uuid"
)

// NotificationRepo is a pure Postgres implementation for notifications.
type NotificationRepo struct {
	q *sqlcdb.Queries
}

func NewNotificationRepo(db sqlcdb.DBTX) *NotificationRepo {
	return &NotificationRepo{q: sqlcdb.New(db)}
}

func (r *NotificationRepo) Create(ctx context.Context, n *models.Notification) error {
	_, err := r.q.CreateNotification(ctx, sqlcdb.CreateNotificationParams{
		ID:          n.ID,
		MemberID:    n.MemberID,
		Type:        n.Type,
		Payload:     n.Payload,
		ScheduledAt: n.ScheduledAt,
		Status:      n.Status,
	})
	return mapErr(err)
}

func (r *NotificationRepo) ListPending(ctx context.Context) ([]*models.Notification, error) {
	rows, err := r.q.ListPendingNotifications(ctx)
	if err != nil {
		return nil, fmt.Errorf("list pending notifications: %w", err)
	}
	notifications := make([]*models.Notification, len(rows))
	for i, row := range rows {
		notifications[i] = mapNotification(row)
	}
	return notifications, nil
}

func (r *NotificationRepo) UpdateStatus(ctx context.Context, id uuid.UUID, status string) error {
	return r.q.UpdateNotificationStatus(ctx, sqlcdb.UpdateNotificationStatusParams{
		ID:     id,
		Status: status,
	})
}

func (r *NotificationRepo) Reschedule(ctx context.Context, id uuid.UUID, scheduledAt time.Time) error {
	return r.q.RescheduleNotification(ctx, sqlcdb.RescheduleNotificationParams{
		ID:          id,
		ScheduledAt: scheduledAt,
	})
}

func mapNotification(row sqlcdb.Notification) *models.Notification {
	n := &models.Notification{
		ID:          row.ID,
		MemberID:    row.MemberID,
		Type:        row.Type,
		Payload:     row.Payload,
		ScheduledAt: row.ScheduledAt,
		Status:      row.Status,
		CreatedAt:   row.CreatedAt,
	}
	if row.SentAt.Valid {
		t := row.SentAt.Time
		n.SentAt = &t
	}
	return n
}
