package postgres

import (
	"context"
	"fmt"

	sqlcdb "github.com/asadlive84/fitness-care-bagerhat/internal/database/sqlc"
	"github.com/asadlive84/fitness-care-bagerhat/internal/models"
	"github.com/google/uuid"
)

// MemberRepo is a pure Postgres implementation — no cache awareness.
type MemberRepo struct {
	q *sqlcdb.Queries
}

func NewMemberRepo(db sqlcdb.DBTX) *MemberRepo {
	return &MemberRepo{q: sqlcdb.New(db)}
}

func (r *MemberRepo) Create(ctx context.Context, m *models.Member, passwordHash string) error {
	_, err := r.q.CreateMember(ctx, sqlcdb.CreateMemberParams{
		ID:                 m.ID,
		Name:               m.Name,
		Phone:              m.Phone,
		PasswordHash:       passwordHash,
		Goal:               nullString(m.Goal),
		JoinDate:           m.JoinDate,
		CurrentWeight:      nullFloat64(m.CurrentWeight),
		Status:             m.Status,
		MustChangePassword: m.MustChangePassword,
	})
	return mapErr(err)
}

func (r *MemberRepo) GetByID(ctx context.Context, id uuid.UUID) (*models.Member, error) {
	row, err := r.q.GetMemberByID(ctx, id)
	if err != nil {
		return nil, fmt.Errorf("get member by id: %w", mapErr(err))
	}
	return mapMember(row), nil
}

func (r *MemberRepo) GetByPhone(ctx context.Context, phone string) (*models.Member, error) {
	row, err := r.q.GetMemberByPhone(ctx, phone)
	if err != nil {
		return nil, fmt.Errorf("get member by phone: %w", mapErr(err))
	}
	return mapMember(row), nil
}

func (r *MemberRepo) GetMemberCredentials(ctx context.Context, phone string) (*models.MemberCredentials, error) {
	row, err := r.q.GetMemberByPhone(ctx, phone)
	if err != nil {
		return nil, fmt.Errorf("get member credentials: %w", mapErr(err))
	}
	return &models.MemberCredentials{
		MemberID:           row.ID,
		PasswordHash:       row.PasswordHash,
		Status:             row.Status,
		MustChangePassword: row.MustChangePassword,
	}, nil
}

func (r *MemberRepo) List(ctx context.Context, f models.MemberFilter) ([]*models.Member, int64, error) {
	rows, err := r.q.ListMembers(ctx, sqlcdb.ListMembersParams{
		Status:      nullString(f.Status),
		Search:      nullString(f.Search),
		LimitCount:  int32(f.Limit),
		OffsetCount: int32(f.Offset()),
	})
	if err != nil {
		return nil, 0, fmt.Errorf("list members: %w", err)
	}

	total, err := r.q.CountMembers(ctx, sqlcdb.CountMembersParams{
		Status: nullString(f.Status),
		Search: nullString(f.Search),
	})
	if err != nil {
		return nil, 0, fmt.Errorf("count members: %w", err)
	}

	members := make([]*models.Member, len(rows))
	for i, row := range rows {
		members[i] = mapMember(row)
	}
	return members, total, nil
}

func (r *MemberRepo) Update(ctx context.Context, m *models.Member) error {
	_, err := r.q.UpdateMember(ctx, sqlcdb.UpdateMemberParams{
		ID:            m.ID,
		Name:          m.Name,
		Phone:         m.Phone,
		Goal:          nullString(m.Goal),
		CurrentWeight: nullFloat64(m.CurrentWeight),
	})
	return mapErr(err)
}

func (r *MemberRepo) UpdateStatus(ctx context.Context, id uuid.UUID, status string) error {
	return mapErr(r.q.UpdateMemberStatus(ctx, sqlcdb.UpdateMemberStatusParams{
		ID:     id,
		Status: status,
	}))
}

func (r *MemberRepo) UpdatePassword(ctx context.Context, id uuid.UUID, hash string) error {
	return mapErr(r.q.UpdateMemberPassword(ctx, sqlcdb.UpdateMemberPasswordParams{
		ID:           id,
		PasswordHash: hash,
	}))
}

func (r *MemberRepo) ListExpiringSoon(ctx context.Context, days int) ([]*models.Member, error) {
	rows, err := r.q.ListMembersWithExpiringSoon(ctx, int32(days))
	if err != nil {
		return nil, fmt.Errorf("list expiring members: %w", err)
	}
	members := make([]*models.Member, len(rows))
	for i, row := range rows {
		members[i] = mapMember(row)
	}
	return members, nil
}
