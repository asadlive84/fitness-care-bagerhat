package models

import (
	"time"

	"github.com/google/uuid"
)

// PlanTemplate is a reusable gym membership plan definition.
type PlanTemplate struct {
	ID           uuid.UUID `json:"id"`
	Name         string    `json:"name"`
	DurationDays int32     `json:"duration_days"`
	DefaultPrice float64   `json:"default_price"`
	CreatedAt    time.Time `json:"created_at"`
	UpdatedAt    time.Time `json:"updated_at"`
}
