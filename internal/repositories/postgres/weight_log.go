package postgres

import (
	"context"
	"fmt"
	"time"

	sqlcdb "github.com/asadlive84/fitness-care-bagerhat/internal/database/sqlc"
	"github.com/asadlive84/fitness-care-bagerhat/internal/models"
	"github.com/google/uuid"
)

// WeightLogRepo is a pure Postgres implementation for weight_logs.
type WeightLogRepo struct {
	q *sqlcdb.Queries
}

func NewWeightLogRepo(db sqlcdb.DBTX) *WeightLogRepo {
	return &WeightLogRepo{q: sqlcdb.New(db)}
}

func (r *WeightLogRepo) Create(ctx context.Context, memberID uuid.UUID, weightKg float64, loggedAt time.Time) error {
	_, err := r.q.CreateWeightLog(ctx, sqlcdb.CreateWeightLogParams{
		ID:       uuid.New(),
		MemberID: memberID,
		WeightKg: weightKg,
		LoggedAt: loggedAt,
	})
	return mapErr(err)
}

func (r *WeightLogRepo) ListByMemberAndDateRange(ctx context.Context, memberID uuid.UUID, from, to time.Time) ([]models.WeightLog, error) {
	rows, err := r.q.ListWeightLogsByMember(ctx, sqlcdb.ListWeightLogsByMemberParams{
		MemberID: memberID,
		FromTime: nullTime(&from),
		ToTime:   nullTime(&to),
	})
	if err != nil {
		return nil, fmt.Errorf("list weight logs: %w", err)
	}
	logs := make([]models.WeightLog, len(rows))
	for i, row := range rows {
		logs[i] = models.WeightLog{ID: row.ID, MemberID: row.MemberID, WeightKg: row.WeightKg, LoggedAt: row.LoggedAt}
	}
	return logs, nil
}

func (r *WeightLogRepo) GetLatestByMemberID(ctx context.Context, memberID uuid.UUID) (*models.WeightLog, error) {
	row, err := r.q.GetLatestWeightLogByMemberID(ctx, memberID)
	if err != nil {
		return nil, fmt.Errorf("get latest weight log: %w", mapErr(err))
	}
	return &models.WeightLog{ID: row.ID, MemberID: row.MemberID, WeightKg: row.WeightKg, LoggedAt: row.LoggedAt}, nil
}

func (r *WeightLogRepo) ListMembersNeedingReminder(ctx context.Context, _ int) ([]*models.Member, error) {
	rows, err := r.q.ListMembersNeedingWeightReminder(ctx)
	if err != nil {
		return nil, fmt.Errorf("list members needing reminder: %w", err)
	}
	members := make([]*models.Member, len(rows))
	for i, row := range rows {
		members[i] = mapMember(row)
	}
	return members, nil
}
