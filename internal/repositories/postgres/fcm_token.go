package postgres

import (
	"context"
	"fmt"

	sqlcdb "github.com/asadlive84/fitness-care-bagerhat/internal/database/sqlc"
	"github.com/google/uuid"
)

// FCMTokenRepo is a pure Postgres implementation for fcm_tokens.
type FCMTokenRepo struct {
	q *sqlcdb.Queries
}

func NewFCMTokenRepo(db sqlcdb.DBTX) *FCMTokenRepo {
	return &FCMTokenRepo{q: sqlcdb.New(db)}
}

func (r *FCMTokenRepo) Upsert(ctx context.Context, memberID uuid.UUID, token string, deviceInfo *string) error {
	_, err := r.q.UpsertFCMToken(ctx, sqlcdb.UpsertFCMTokenParams{
		ID:         uuid.New(),
		MemberID:   memberID,
		Token:      token,
		DeviceInfo: nullString(deviceInfo),
	})
	return mapErr(err)
}

func (r *FCMTokenRepo) ListTokensByMember(ctx context.Context, memberID uuid.UUID) ([]string, error) {
	rows, err := r.q.ListFCMTokensByMemberID(ctx, memberID)
	if err != nil {
		return nil, fmt.Errorf("list fcm tokens: %w", err)
	}
	tokens := make([]string, len(rows))
	for i, row := range rows {
		tokens[i] = row.Token
	}
	return tokens, nil
}

func (r *FCMTokenRepo) Delete(ctx context.Context, token string) error {
	return r.q.DeleteFCMToken(ctx, token)
}
