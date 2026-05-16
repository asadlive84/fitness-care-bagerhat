package postgres

import (
	"context"
	"fmt"
	"time"

	sqlcdb "github.com/asadlive84/fitness-care-bagerhat/internal/database/sqlc"
	"github.com/asadlive84/fitness-care-bagerhat/internal/models"
	"github.com/google/uuid"
)

// WorkoutLogRepo is a pure Postgres implementation for workout_logs.
type WorkoutLogRepo struct {
	q *sqlcdb.Queries
}

func NewWorkoutLogRepo(db sqlcdb.DBTX) *WorkoutLogRepo {
	return &WorkoutLogRepo{q: sqlcdb.New(db)}
}

func (r *WorkoutLogRepo) Create(ctx context.Context, memberID uuid.UUID, content string, loggedAt time.Time) error {
	_, err := r.q.CreateWorkoutLog(ctx, sqlcdb.CreateWorkoutLogParams{
		ID:       uuid.New(),
		MemberID: memberID,
		Content:  content,
		LoggedAt: loggedAt,
	})
	return mapErr(err)
}

func (r *WorkoutLogRepo) ListByMemberID(ctx context.Context, memberID uuid.UUID, page, limit int) ([]models.WorkoutLog, error) {
	if page < 1 {
		page = 1
	}
	rows, err := r.q.ListWorkoutLogsByMemberID(ctx, sqlcdb.ListWorkoutLogsByMemberIDParams{
		MemberID:    memberID,
		LimitCount:  int32(limit),
		OffsetCount: int32((page - 1) * limit),
	})
	if err != nil {
		return nil, fmt.Errorf("list workout logs: %w", err)
	}
	logs := make([]models.WorkoutLog, len(rows))
	for i, row := range rows {
		logs[i] = models.WorkoutLog{ID: row.ID, MemberID: row.MemberID, Content: row.Content, LoggedAt: row.LoggedAt}
	}
	return logs, nil
}
