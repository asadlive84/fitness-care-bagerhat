// Package repositories defines the repository interfaces consumed by the service
// layer. The actual implementations live in the postgres/ and cached/
// sub-packages; the service layer depends only on these interfaces.
package repositories

import (
	"context"
	"encoding/json"
	"time"

	"github.com/asadlive84/fitness-care-bagerhat/internal/models"
	"github.com/google/uuid"
)

// MemberRepository covers all persistence operations for members.
type MemberRepository interface {
	// Create persists a new member. The member.ID must be set by the caller.
	Create(ctx context.Context, m *models.Member, passwordHash string) error

	// GetByID returns a member by primary key.
	GetByID(ctx context.Context, id uuid.UUID) (*models.Member, error)

	// GetByPhone returns a member by their unique phone number.
	GetByPhone(ctx context.Context, phone string) (*models.Member, error)

	// GetMemberCredentials returns the password hash and status needed for login.
	// This method MUST NOT be cached — it is only called during authentication.
	GetMemberCredentials(ctx context.Context, phone string) (*models.MemberCredentials, error)

	// List returns a paginated, filtered member list and total count.
	List(ctx context.Context, filter models.MemberFilter) ([]*models.Member, int64, error)

	// Update saves profile changes and invalidates the member's cache entries.
	Update(ctx context.Context, m *models.Member) error

	// UpdateStatus sets the active/inactive status.
	UpdateStatus(ctx context.Context, id uuid.UUID, status string) error

	// UpdatePassword stores a new bcrypt hash and clears must_change_password.
	// Used when a member changes their own password.
	UpdatePassword(ctx context.Context, id uuid.UUID, hash string) error

	// ResetPasswordByAdmin stores a new bcrypt hash and SETS must_change_password
	// to true, forcing the member to change on their next login.
	ResetPasswordByAdmin(ctx context.Context, id uuid.UUID, hash string) error

	// ListExpiringSoon returns active members whose active subscription ends
	// within the given number of days.
	ListExpiringSoon(ctx context.Context, days int) ([]*models.Member, error)

	// Delete permanently removes a member and all their associated records
	// (subscriptions, payments, logs, messages, notifications, FCM tokens)
	// in a single atomic transaction.
	Delete(ctx context.Context, id uuid.UUID) error
}

// AdminRepository covers persistence for the single admin account.
type AdminRepository interface {
	Create(ctx context.Context, a *models.Admin, passwordHash string) error
	GetByID(ctx context.Context, id uuid.UUID) (*models.Admin, error)
	GetByEmail(ctx context.Context, email string) (*models.Admin, error)
	GetAdminCredentials(ctx context.Context, email string) (*models.AdminCredentials, error)
	UpdatePassword(ctx context.Context, id uuid.UUID, hash string) error
}

// PlanRepository covers plan_templates persistence.
type PlanRepository interface {
	Create(ctx context.Context, p *models.PlanTemplate) error
	GetByID(ctx context.Context, id uuid.UUID) (*models.PlanTemplate, error)
	List(ctx context.Context) ([]*models.PlanTemplate, error)
	Update(ctx context.Context, p *models.PlanTemplate) error
	Delete(ctx context.Context, id uuid.UUID) error
}

// SubscriptionRepository covers subscriptions persistence.
type SubscriptionRepository interface {
	Create(ctx context.Context, s *models.Subscription) error
	GetActiveByMemberID(ctx context.Context, memberID uuid.UUID) (*models.Subscription, error)
	ListByMemberID(ctx context.Context, memberID uuid.UUID) ([]*models.Subscription, error)

	// UpdateStatus changes subscription status. memberID is required so the
	// cached implementation can invalidate member:{id}:subscription:active.
	UpdateStatus(ctx context.Context, id uuid.UUID, memberID uuid.UUID, status string) error

	// ReplaceActive marks all active subscriptions for a member as 'replaced'.
	ReplaceActive(ctx context.Context, memberID uuid.UUID) error

	// UpdateActive updates price, end_date, and note of the current active
	// subscription in place. Returns ErrNotFound if no active subscription exists.
	UpdateActive(ctx context.Context, memberID uuid.UUID, endDate time.Time, finalPrice float64, note *string) (*models.Subscription, error)

	// ListExpiring returns active subscriptions ending within the given days.
	ListExpiring(ctx context.Context, days int) ([]*models.ExpiringSubscription, error)
}

// SettingRepository covers the settings key-value store.
type SettingRepository interface {
	GetAll(ctx context.Context) ([]*models.Setting, error)
	GetByKey(ctx context.Context, key string) (*models.Setting, error)
	Upsert(ctx context.Context, key string, value json.RawMessage) (*models.Setting, error)
}

// NotificationRepository covers the notifications queue used by the scheduler.
type NotificationRepository interface {
	Create(ctx context.Context, n *models.Notification) error
	ListPending(ctx context.Context) ([]*models.Notification, error)
	UpdateStatus(ctx context.Context, id uuid.UUID, status string) error
	Reschedule(ctx context.Context, id uuid.UUID, scheduledAt time.Time) error
}

// FCMTokenRepository covers device push tokens.
type FCMTokenRepository interface {
	Upsert(ctx context.Context, memberID uuid.UUID, token string, deviceInfo *string) error
	ListTokensByMember(ctx context.Context, memberID uuid.UUID) ([]string, error)
	Delete(ctx context.Context, token string) error
}

// MessageRepository covers messaging persistence (never cached — near-realtime).
type MessageRepository interface {
	Create(ctx context.Context, m *models.Message) error
	ListDirectByMember(ctx context.Context, memberID uuid.UUID) ([]*models.Message, error)
	GetLatestDirectByMember(ctx context.Context, memberID uuid.UUID) (*models.Message, error)
	ListConversationMemberIDs(ctx context.Context) ([]uuid.UUID, error)
	ListBroadcasts(ctx context.Context, page, limit int) ([]*models.Message, error)
	ListMemberMessages(ctx context.Context, memberID uuid.UUID, page, limit int) ([]*models.Message, error)
	MarkMemberMessagesRead(ctx context.Context, memberID uuid.UUID) error
	MarkAdminMessagesRead(ctx context.Context, memberID uuid.UUID) error
}

// PaymentRepository covers payments persistence (never cached — financial accuracy).
type PaymentRepository interface {
	Create(ctx context.Context, p *models.Payment) error
	ListByMember(ctx context.Context, memberID uuid.UUID, filter models.PaymentFilter) ([]*models.Payment, error)
	GetSummaryByMonth(ctx context.Context, month time.Time) (*models.PaymentSummary, error)
}

// WeightLogRepository covers weight_logs persistence (not cached).
type WeightLogRepository interface {
	Create(ctx context.Context, memberID uuid.UUID, weightKg float64, loggedAt time.Time) error
	ListByMemberAndDateRange(ctx context.Context, memberID uuid.UUID, from, to time.Time) ([]models.WeightLog, error)
	GetLatestByMemberID(ctx context.Context, memberID uuid.UUID) (*models.WeightLog, error)
	ListMembersNeedingReminder(ctx context.Context, days int) ([]*models.Member, error)
}

// WorkoutLogRepository covers workout_logs persistence (not cached).
type WorkoutLogRepository interface {
	Create(ctx context.Context, memberID uuid.UUID, content string, loggedAt time.Time) error
	ListByMemberID(ctx context.Context, memberID uuid.UUID, page, limit int) ([]models.WorkoutLog, error)
}

// DietLogRepository covers diet_logs persistence (not cached).
type DietLogRepository interface {
	Create(ctx context.Context, memberID uuid.UUID, content string, loggedAt time.Time) error
	ListByMemberID(ctx context.Context, memberID uuid.UUID, page, limit int) ([]models.DietLog, error)
}
