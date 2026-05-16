package services

import (
	"context"
	"encoding/json"
	"fmt"

	"github.com/asadlive84/fitness-care-bagerhat/internal/models"
	"github.com/asadlive84/fitness-care-bagerhat/internal/repositories"
)

// SettingService handles settings reads and writes with Redis caching.
type SettingService struct {
	settings repositories.SettingRepository
}

// NewSettingService constructs a SettingService.
func NewSettingService(settings repositories.SettingRepository) *SettingService {
	return &SettingService{settings: settings}
}

// GetAll returns all settings (served from cache when warm).
func (s *SettingService) GetAll(ctx context.Context) ([]*models.Setting, error) {
	all, err := s.settings.GetAll(ctx)
	if err != nil {
		return nil, fmt.Errorf("get settings: %w", err)
	}
	return all, nil
}

// UpsertSetting creates or updates a single setting key.
func (s *SettingService) UpsertSetting(ctx context.Context, key string, value json.RawMessage) (*models.Setting, error) {
	setting, err := s.settings.Upsert(ctx, key, value)
	if err != nil {
		return nil, fmt.Errorf("upsert setting %q: %w", key, err)
	}
	return setting, nil
}

// GetQuietWindow parses the quiet_window setting.
// Falls back to a safe default (22:00–07:00) if not configured.
func (s *SettingService) GetQuietWindow(ctx context.Context) (models.QuietWindow, error) {
	setting, err := s.settings.GetByKey(ctx, "quiet_window")
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
func (s *SettingService) GetNudgeDays(ctx context.Context) int {
	setting, err := s.settings.GetByKey(ctx, "nudge_days")
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
func (s *SettingService) GetWeightReminderDays(ctx context.Context) int {
	setting, err := s.settings.GetByKey(ctx, "weight_reminder_days")
	if err != nil {
		return 7
	}
	var days int
	if err := json.Unmarshal(setting.Value, &days); err != nil || days <= 0 {
		return 7
	}
	return days
}
