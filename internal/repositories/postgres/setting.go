package postgres

import (
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"fmt"

	sqlcdb "github.com/asadlive84/fitness-care-bagerhat/internal/database/sqlc"
	"github.com/asadlive84/fitness-care-bagerhat/internal/models"
)

// SettingRepo is a pure Postgres implementation for settings.
type SettingRepo struct {
	q *sqlcdb.Queries
}

func NewSettingRepo(db sqlcdb.DBTX) *SettingRepo {
	return &SettingRepo{q: sqlcdb.New(db)}
}

func (r *SettingRepo) GetAll(ctx context.Context) ([]*models.Setting, error) {
	rows, err := r.q.GetAllSettings(ctx)
	if err != nil {
		return nil, fmt.Errorf("get all settings: %w", err)
	}
	settings := make([]*models.Setting, len(rows))
	for i, row := range rows {
		settings[i] = mapSetting(row)
	}
	return settings, nil
}

func (r *SettingRepo) GetByKey(ctx context.Context, key string) (*models.Setting, error) {
	row, err := r.q.GetSettingByKey(ctx, key)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, fmt.Errorf("setting not found: %s", key)
	}
	if err != nil {
		return nil, fmt.Errorf("get setting by key: %w", err)
	}
	return mapSetting(row), nil
}

func (r *SettingRepo) Upsert(ctx context.Context, key string, value json.RawMessage) (*models.Setting, error) {
	row, err := r.q.UpsertSetting(ctx, sqlcdb.UpsertSettingParams{
		Key:   key,
		Value: value,
	})
	if err != nil {
		return nil, fmt.Errorf("upsert setting: %w", err)
	}
	return mapSetting(row), nil
}
