package models

import (
	"time"

	"github.com/google/uuid"
)

type WeightLog struct {
	ID       uuid.UUID `json:"id"`
	MemberID uuid.UUID `json:"member_id"`
	WeightKg float64   `json:"weight_kg"`
	LoggedAt time.Time `json:"logged_at"`
}

type WorkoutLog struct {
	ID       uuid.UUID `json:"id"`
	MemberID uuid.UUID `json:"member_id"`
	Content  string    `json:"content"`
	LoggedAt time.Time `json:"logged_at"`
}

type DietLog struct {
	ID       uuid.UUID `json:"id"`
	MemberID uuid.UUID `json:"member_id"`
	Content  string    `json:"content"`
	LoggedAt time.Time `json:"logged_at"`
}
