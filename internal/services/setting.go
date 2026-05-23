package services

import (
	"context"
	"encoding/json"
	"fmt"

	"github.com/asadlive84/fitness-care-bagerhat/internal/models"
	"github.com/asadlive84/fitness-care-bagerhat/internal/repositories"
	"github.com/google/uuid"
)

// SettingService handles settings reads and writes with Redis caching.
type SettingService struct {
	settings repositories.SettingRepository
}

// NewSettingService constructs a SettingService.
func NewSettingService(settings repositories.SettingRepository) *SettingService {
	return &SettingService{settings: settings}
}

// GetAll returns all settings scoped to the admin (served from cache when warm).
func (s *SettingService) GetAll(ctx context.Context, adminID *uuid.UUID) ([]*models.Setting, error) {
	all, err := s.settings.GetAll(ctx, adminID)
	if err != nil {
		return nil, fmt.Errorf("get settings: %w", err)
	}
	return all, nil
}

// UpsertSetting creates or updates a single setting key scoped to the admin.
func (s *SettingService) UpsertSetting(ctx context.Context, key string, value json.RawMessage, adminID *uuid.UUID) (*models.Setting, error) {
	setting, err := s.settings.Upsert(ctx, key, value, adminID)
	if err != nil {
		return nil, fmt.Errorf("upsert setting %q: %w", key, err)
	}
	return setting, nil
}

// GetQuietWindow parses the quiet_window setting.
// Falls back to a safe default (22:00–07:00) if not configured.
func (s *SettingService) GetQuietWindow(ctx context.Context, adminID *uuid.UUID) (models.QuietWindow, error) {
	setting, err := s.settings.GetByKey(ctx, "quiet_window", adminID)
	if err != nil {
		// Return default — don't fail if setting is missing.
		return models.QuietWindow{Start: "22:00", End: "07:00"}, nil
	}
	var qw models.QuietWindow
	if err := json.Unmarshal(setting.Value, &qw); err != nil {
		return models.QuietWindow{Start: "22:00", End: "07:00"}, nil
	}
	return qw, nil
}

// GetNudgeDays returns the number of days before subscription expiry to send reminders.
func (s *SettingService) GetNudgeDays(ctx context.Context, adminID *uuid.UUID) int {
	setting, err := s.settings.GetByKey(ctx, "nudge_days", adminID)
	if err != nil {
		return 7
	}
	var days int
	if err := json.Unmarshal(setting.Value, &days); err != nil || days <= 0 {
		return 7
	}
	return days
}

// GetWeightReminderDays returns the number of idle days before a weight reminder is sent.
func (s *SettingService) GetWeightReminderDays(ctx context.Context, adminID *uuid.UUID) int {
	setting, err := s.settings.GetByKey(ctx, "weight_reminder_days", adminID)
	if err != nil {
		return 7
	}
	var days int
	if err := json.Unmarshal(setting.Value, &days); err != nil || days <= 0 {
		return 7
	}
	return days
}

// GetGracePeriods returns the grace periods for prepaid and postpaid.
func (s *SettingService) GetGracePeriods(ctx context.Context, adminID *uuid.UUID) models.GracePeriod {
	setting, err := s.settings.GetByKey(ctx, "grace_periods", adminID)
	if err != nil {
		return models.GracePeriod{PrepaidDays: 5, PostpaidDays: 5} // Fallback to 5 days
	}
	var gp models.GracePeriod
	if err := json.Unmarshal(setting.Value, &gp); err != nil {
		return models.GracePeriod{PrepaidDays: 5, PostpaidDays: 5}
	}
	return gp
}
