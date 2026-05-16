package postgres

import (
	"context"
	"database/sql"
	"fmt"
	"time"

	"github.com/google/uuid"
	sqlcdb "github.com/asadlive84/fitness-care-bagerhat/internal/database/sqlc"
	"github.com/asadlive84/fitness-care-bagerhat/internal/models"
)

// MessageRepo is a pure Postgres implementation for messages.
type MessageRepo struct {
	q *sqlcdb.Queries
}

func NewMessageRepo(db sqlcdb.DBTX) *MessageRepo {
	return &MessageRepo{q: sqlcdb.New(db)}
}

func (r *MessageRepo) Create(ctx context.Context, m *models.Message) error {
	var receiverID uuid.NullUUID
	if m.ReceiverID != nil {
		receiverID = uuid.NullUUID{UUID: *m.ReceiverID, Valid: true}
	}

	_, err := r.q.CreateMessage(ctx, sqlcdb.CreateMessageParams{
		ID:              m.ID,
		SenderID:        m.SenderID,
		SenderRole:      m.SenderRole,
		ReceiverID:      receiverID,
		IsBroadcast:     m.IsBroadcast,
		BroadcastFilter: nullString(m.BroadcastFilter),
		Content:         m.Content,
		SentAt:          m.SentAt,
	})
	return mapErr(err)
}

func (r *MessageRepo) ListDirectByMember(ctx context.Context, memberID uuid.UUID) ([]*models.Message, error) {
	rows, err := r.q.ListDirectMessagesByMember(ctx, memberID)
	if err != nil {
		return nil, fmt.Errorf("list direct messages: %w", err)
	}
	return mapMessages(rows), nil
}

func (r *MessageRepo) GetLatestDirectByMember(ctx context.Context, memberID uuid.UUID) (*models.Message, error) {
	row, err := r.q.GetLatestDirectMessageByMember(ctx, memberID)
	if err != nil {
		return nil, fmt.Errorf("get latest message: %w", mapErr(err))
	}
	return mapMessage(row), nil
}

func (r *MessageRepo) ListConversationMemberIDs(ctx context.Context) ([]uuid.UUID, error) {
	rows, err := r.q.ListConversationMemberIDs(ctx)
	if err != nil {
		return nil, fmt.Errorf("list conversation member ids: %w", err)
	}
	ids := make([]uuid.UUID, 0, len(rows))
	for _, raw := range rows {
		if raw == nil {
			continue
		}
		switch v := raw.(type) {
		case string:
			if id, e := uuid.Parse(v); e == nil {
				ids = append(ids, id)
			}
		case []byte:
			if id, e := uuid.ParseBytes(v); e == nil {
				ids = append(ids, id)
			}
		case [16]byte:
			ids = append(ids, uuid.UUID(v))
		}
	}
	return ids, nil
}

func (r *MessageRepo) ListBroadcasts(ctx context.Context, page, limit int) ([]*models.Message, error) {
	if page < 1 {
		page = 1
	}
	rows, err := r.q.ListBroadcasts(ctx, sqlcdb.ListBroadcastsParams{
		LimitCount:  int32(limit),
		OffsetCount: int32((page - 1) * limit),
	})
	if err != nil {
		return nil, fmt.Errorf("list broadcasts: %w", err)
	}
	return mapMessages(rows), nil
}

func (r *MessageRepo) ListMemberMessages(ctx context.Context, memberID uuid.UUID, page, limit int) ([]*models.Message, error) {
	if page < 1 {
		page = 1
	}
	rows, err := r.q.ListMemberMessages(ctx, sqlcdb.ListMemberMessagesParams{
		MemberID:    memberID,
		LimitCount:  int32(limit),
		OffsetCount: int32((page - 1) * limit),
	})
	if err != nil {
		return nil, fmt.Errorf("list member messages: %w", err)
	}
	return mapMessages(rows), nil
}

func (r *MessageRepo) MarkMemberMessagesRead(ctx context.Context, memberID uuid.UUID) error {
	return r.q.MarkMemberMessagesAsRead(ctx, memberID)
}

func (r *MessageRepo) MarkAdminMessagesRead(ctx context.Context, memberID uuid.UUID) error {
	return r.q.MarkAdminMessagesAsRead(ctx, uuid.NullUUID{UUID: memberID, Valid: true})
}

// ── mappers ───────────────────────────────────────────────────────────────────

func mapMessage(row sqlcdb.Message) *models.Message {
	m := &models.Message{
		ID:          row.ID,
		SenderID:    row.SenderID,
		SenderRole:  row.SenderRole,
		IsBroadcast: row.IsBroadcast,
		Content:     row.Content,
		SentAt:      row.SentAt,
	}
	if row.ReceiverID.Valid {
		m.ReceiverID = &row.ReceiverID.UUID
	}
	if row.BroadcastFilter.Valid {
		m.BroadcastFilter = &row.BroadcastFilter.String
	}
	if row.ReadAt.Valid {
		m.ReadAt = &row.ReadAt.Time
	}
	return m
}

func mapMessages(rows []sqlcdb.Message) []*models.Message {
	msgs := make([]*models.Message, len(rows))
	for i, row := range rows {
		msgs[i] = mapMessage(row)
	}
	return msgs
}

// nullUUID wraps a uuid pointer in a uuid.NullUUID.
func nullUUID(id *uuid.UUID) uuid.NullUUID {
	if id == nil {
		return uuid.NullUUID{}
	}
	return uuid.NullUUID{UUID: *id, Valid: true}
}

// Ensure time is used (LoggedAt in weight log uses it).
var _ = time.Now
var _ = sql.NullString{}
