package cached

import (
	"context"
	"encoding/json"
	"errors"
	"log/slog"
	"time"

	"github.com/asadlive84/fitness-care-bagerhat/internal/cache"
	"github.com/asadlive84/fitness-care-bagerhat/internal/models"
	"github.com/asadlive84/fitness-care-bagerhat/internal/repositories"
	"github.com/google/uuid"
)

const (
	settingsTTL = 24 * time.Hour
)

// SettingRepo wraps a SettingRepository, caching the full settings map under a tenant-scoped key.
type SettingRepo struct {
	db    repositories.SettingRepository
	cache *cache.Client
	log   *slog.Logger
}

func NewSettingRepo(db repositories.SettingRepository, c *cache.Client, log *slog.Logger) *SettingRepo {
	return &SettingRepo{db: db, cache: c, log: log}
}

func getCacheKey(adminID *uuid.UUID) string {
	if adminID == nil {
		return "settings:all:global"
	}
	return "settings:all:" + adminID.String()
}

// GetAll implements cache-aside for the tenant-scoped settings key.
func (r *SettingRepo) GetAll(ctx context.Context, adminID *uuid.UUID) ([]*models.Setting, error) {
	key := getCacheKey(adminID)
	var settings []*models.Setting
	if err := r.cache.GetJSON(ctx, key, &settings); err == nil {
		return settings, nil // cache HIT
	} else if !errors.Is(err, cache.ErrCacheMiss) {
		r.log.WarnContext(ctx, "cache get settings", "error", err)
	}

	settings, err := r.db.GetAll(ctx, adminID)
	if err != nil {
		return nil, err
	}

	if setErr := r.cache.SetJSON(ctx, key, settings, settingsTTL); setErr != nil {
		r.log.WarnContext(ctx, "cache set settings", "error", setErr)
	}
	return settings, nil
}

// GetByKey goes to DB directly.
func (r *SettingRepo) GetByKey(ctx context.Context, key string, adminID *uuid.UUID) (*models.Setting, error) {
	return r.db.GetByKey(ctx, key, adminID)
}

// Upsert writes to DB then busts the tenant-scoped cache.
func (r *SettingRepo) Upsert(ctx context.Context, key string, value json.RawMessage, adminID *uuid.UUID) (*models.Setting, error) {
	s, err := r.db.Upsert(ctx, key, value, adminID)
	if err != nil {
		return nil, err
	}
	cacheKey := getCacheKey(adminID)
	if delErr := r.cache.Delete(ctx, cacheKey); delErr != nil {
		r.log.WarnContext(ctx, "cache delete settings", "error", delErr)
	}
	return s, nil
}
