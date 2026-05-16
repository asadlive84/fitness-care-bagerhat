package postgres

import (
	"context"
	"fmt"
	"time"

	sqlcdb "github.com/asadlive84/fitness-care-bagerhat/internal/database/sqlc"
	"github.com/asadlive84/fitness-care-bagerhat/internal/models"
	"github.com/google/uuid"
)

// DietLogRepo is a pure Postgres implementation for diet_logs.
type DietLogRepo struct {
	q *sqlcdb.Queries
}

func NewDietLogRepo(db sqlcdb.DBTX) *DietLogRepo {
	return &DietLogRepo{q: sqlcdb.New(db)}
}

func (r *DietLogRepo) Create(ctx context.Context, memberID uuid.UUID, content string, loggedAt time.Time) error {
	_, err := r.q.CreateDietLog(ctx, sqlcdb.CreateDietLogParams{
		ID:       uuid.New(),
		MemberID: memberID,
		Content:  content,
		LoggedAt: loggedAt,
	})
	return mapErr(err)
}

func (r *DietLogRepo) ListByMemberID(ctx context.Context, memberID uuid.UUID, page, limit int) ([]models.DietLog, error) {
	if page < 1 {
		page = 1
	}
	rows, err := r.q.ListDietLogsByMemberID(ctx, sqlcdb.ListDietLogsByMemberIDParams{
		MemberID:    memberID,
		LimitCount:  int32(limit),
		OffsetCount: int32((page - 1) * limit),
	})
	if err != nil {
		return nil, fmt.Errorf("list diet logs: %w", err)
	}
	logs := make([]models.DietLog, len(rows))
	for i, row := range rows {
		logs[i] = models.DietLog{ID: row.ID, MemberID: row.MemberID, Content: row.Content, LoggedAt: row.LoggedAt}
	}
	return logs, nil
}
