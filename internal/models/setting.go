package models

import (
	"encoding/json"
	"time"

	"github.com/google/uuid"
)

// Setting is a key-value configuration entry backed by JSONB.
type Setting struct {
	Key       string          `json:"key"`
	Value     json.RawMessage `json:"value"`
	UpdatedAt time.Time       `json:"updated_at"`
	AdminID   *uuid.UUID      `json:"admin_id,omitempty"`
}

// QuietWindow holds the notification suppression window configuration.
type QuietWindow struct {
	Start string `json:"start"` // "22:00"
	End   string `json:"end"`   // "07:00"
}

// GracePeriod holds the global subscription grace period configuration.
type GracePeriod struct {
	PrepaidDays  int `json:"prepaid_days"`
	PostpaidDays int `json:"postpaid_days"`
}
