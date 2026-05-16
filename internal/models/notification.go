package models

import (
	"encoding/json"
	"time"

	"github.com/google/uuid"
)

// Notification is a queued push notification entry.
type Notification struct {
	ID          uuid.UUID       `json:"id"`
	MemberID    uuid.UUID       `json:"member_id"`
	Type        string          `json:"type"`    // renewal | weight_reminder | message
	Payload     json.RawMessage `json:"payload"` // type-specific data
	ScheduledAt time.Time       `json:"scheduled_at"`
	SentAt      *time.Time      `json:"sent_at,omitempty"`
	Status      string          `json:"status"` // pending | sent | failed
	CreatedAt   time.Time       `json:"created_at"`
}

// FCMToken is a device push token registered by a member.
type FCMToken struct {
	ID           uuid.UUID `json:"id"`
	MemberID     uuid.UUID `json:"member_id"`
	Token        string    `json:"token"`
	DeviceInfo   *string   `json:"device_info,omitempty"`
	LastActiveAt time.Time `json:"last_active_at"`
	CreatedAt    time.Time `json:"created_at"`
}

// RenewalPayload is stored in Notification.Payload for renewal reminders.
type RenewalPayload struct {
	MemberName string    `json:"member_name"`
	PlanName   string    `json:"plan_name"`
	EndDate    time.Time `json:"end_date"`
	DaysLeft   int       `json:"days_left"`
}

// WeightReminderPayload is stored in Notification.Payload for weight reminders.
type WeightReminderPayload struct {
	MemberName   string `json:"member_name"`
	DaysSinceLog int    `json:"days_since_log"`
}
