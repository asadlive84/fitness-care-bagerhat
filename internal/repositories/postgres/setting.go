package postgres

import (
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"fmt"

	sqlcdb "github.com/asadlive84/fitness-care-bagerhat/internal/database/sqlc"
	"github.com/asadlive84/fitness-care-bagerhat/internal/models"
	"github.com/google/uuid"
)

// SettingRepo is a pure Postgres implementation for settings.
type SettingRepo struct {
	q *sqlcdb.Queries
}

func NewSettingRepo(db sqlcdb.DBTX) *SettingRepo {
	return &SettingRepo{q: sqlcdb.New(db)}
}

func (r *SettingRepo) GetAll(ctx context.Context, adminID *uuid.UUID) ([]*models.Setting, error) {
	var dbAdminID uuid.NullUUID
	if adminID != nil {
		dbAdminID = uuid.NullUUID{UUID: *adminID, Valid: true}
	}
	rows, err := r.q.GetAllSettings(ctx, dbAdminID)
	if err != nil {
		return nil, fmt.Errorf("get all settings: %w", err)
	}
	settings := make([]*models.Setting, len(rows))
	for i, row := range rows {
		settings[i] = mapGetAllSettingsRow(row)
	}
	return settings, nil
}

func (r *SettingRepo) GetByKey(ctx context.Context, key string, adminID *uuid.UUID) (*models.Setting, error) {
	var dbAdminID uuid.NullUUID
	if adminID != nil {
		dbAdminID = uuid.NullUUID{UUID: *adminID, Valid: true}
	}
	row, err := r.q.GetSettingByKey(ctx, sqlcdb.GetSettingByKeyParams{
		Key:     key,
		AdminID: dbAdminID,
	})
	if errors.Is(err, sql.ErrNoRows) {
		return nil, fmt.Errorf("setting not found: %s", key)
	}
	if err != nil {
		return nil, fmt.Errorf("get setting by key: %w", err)
	}
	return mapSetting(row), nil
}

func (r *SettingRepo) Upsert(ctx context.Context, key string, value json.RawMessage, adminID *uuid.UUID) (*models.Setting, error) {
	var row sqlcdb.Setting
	var err error

	if adminID == nil {
		row, err = r.q.UpsertSettingGlobal(ctx, sqlcdb.UpsertSettingGlobalParams{
			Key:   key,
			Value: value,
		})
	} else {
		row, err = r.q.UpsertSettingTenant(ctx, sqlcdb.UpsertSettingTenantParams{
			Key:     key,
			Value:   value,
			AdminID: uuid.NullUUID{UUID: *adminID, Valid: true},
		})
	}

	if err != nil {
		return nil, fmt.Errorf("upsert setting: %w", err)
	}
	return mapSetting(row), nil
}
