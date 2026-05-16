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
)

const (
	settingsCacheKey = "settings:all"
	settingsTTL      = 24 * time.Hour
)

// SettingRepo wraps a SettingRepository, caching the full settings map under "settings:all".
type SettingRepo struct {
	db    repositories.SettingRepository
	cache *cache.Client
	log   *slog.Logger
}

func NewSettingRepo(db repositories.SettingRepository, c *cache.Client, log *slog.Logger) *SettingRepo {
	return &SettingRepo{db: db, cache: c, log: log}
}

// GetAll implements cache-aside for "settings:all".
func (r *SettingRepo) GetAll(ctx context.Context) ([]*models.Setting, error) {
	var settings []*models.Setting
	if err := r.cache.GetJSON(ctx, settingsCacheKey, &settings); err == nil {
		return settings, nil // cache HIT
	} else if !errors.Is(err, cache.ErrCacheMiss) {
		r.log.WarnContext(ctx, "cache get settings", "error", err)
	}

	settings, err := r.db.GetAll(ctx)
	if err != nil {
		return nil, err
	}

	if setErr := r.cache.SetJSON(ctx, settingsCacheKey, settings, settingsTTL); setErr != nil {
		r.log.WarnContext(ctx, "cache set settings", "error", setErr)
	}
	return settings, nil
}

// GetByKey goes to DB directly — individual key reads are rare (scheduler
// startup) and GetAll handles the high-frequency path.
func (r *SettingRepo) GetByKey(ctx context.Context, key string) (*models.Setting, error) {
	return r.db.GetByKey(ctx, key)
}

// Upsert writes to DB then busts the settings list cache.
func (r *SettingRepo) Upsert(ctx context.Context, key string, value json.RawMessage) (*models.Setting, error) {
	s, err := r.db.Upsert(ctx, key, value)
	if err != nil {
		return nil, err
	}
	if delErr := r.cache.Delete(ctx, settingsCacheKey); delErr != nil {
		r.log.WarnContext(ctx, "cache delete settings", "error", delErr)
	}
	return s, nil
}
