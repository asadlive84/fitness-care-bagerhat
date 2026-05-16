package models

import (
	"encoding/json"
	"time"
)

// Setting is a key-value configuration entry backed by JSONB.
type Setting struct {
	Key       string          `json:"key"`
	Value     json.RawMessage `json:"value"`
	UpdatedAt time.Time       `json:"updated_at"`
}

// QuietWindow holds the notification suppression window configuration.
type QuietWindow struct {
	Start string `json:"start"` // "22:00"
	End   string `json:"end"`   // "07:00"
}
