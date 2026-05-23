package postgres

import (
	"context"
	"database/sql"
	"errors"
	"fmt"

	sqlcdb "github.com/asadlive84/fitness-care-bagerhat/internal/database/sqlc"
	"github.com/asadlive84/fitness-care-bagerhat/internal/models"
	"github.com/google/uuid"
)

// AdminRepo is a pure Postgres implementation for admins.
type AdminRepo struct {
	q  *sqlcdb.Queries
	db sqlcdb.DBTX // kept for raw queries (e.g. CreateSuperAdmin)
}

func NewAdminRepo(db sqlcdb.DBTX) *AdminRepo {
	return &AdminRepo{q: sqlcdb.New(db), db: db}
}

func (r *AdminRepo) Create(ctx context.Context, a *models.Admin, passwordHash string) error {
	_, err := r.q.CreateAdmin(ctx, sqlcdb.CreateAdminParams{
		ID:                    a.ID,
		Name:                  a.Name,
		Phone:                 nullString(a.Phone),
		Email:                 a.Email,
		PasswordHash:          passwordHash,
		Role:                  a.Role,
		ParentAdminID:         nullUUID(a.ParentAdminID),
		CreatedBySuperadminID: nullUUID(a.CreatedBySuperadminID),
	})
	return err
}

// CreateSuperAdmin inserts an admin with role = 'superadmin' using raw SQL
// so we don't need to regenerate sqlc code for a single extra column.
func (r *AdminRepo) CreateSuperAdmin(ctx context.Context, a *models.Admin, passwordHash string) error {
	const rawSQL = `INSERT INTO admins (id, name, email, password_hash, role)
	                VALUES ($1, $2, $3, $4, 'superadmin')`
	_, err := r.db.ExecContext(ctx, rawSQL, a.ID, a.Name, a.Email, passwordHash)
	return err
}

func (r *AdminRepo) GetByID(ctx context.Context, id uuid.UUID) (*models.Admin, error) {
	row, err := r.q.GetAdminByID(ctx, id)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, fmt.Errorf("admin not found")
	}
	if err != nil {
		return nil, fmt.Errorf("get admin by id: %w", err)
	}
	return mapAdmin(row), nil
}

func (r *AdminRepo) GetByEmail(ctx context.Context, email string) (*models.Admin, error) {
	row, err := r.q.GetAdminByEmail(ctx, email)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, fmt.Errorf("admin not found")
	}
	if err != nil {
		return nil, fmt.Errorf("get admin by email: %w", err)
	}
	return mapAdmin(row), nil
}

func (r *AdminRepo) GetAdminCredentials(ctx context.Context, email string) (*models.AdminCredentials, error) {
	row, err := r.q.GetAdminByEmail(ctx, email)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, fmt.Errorf("admin not found")
	}
	if err != nil {
		return nil, fmt.Errorf("get admin credentials: %w", err)
	}
	return &models.AdminCredentials{
		AdminID:      row.ID,
		PasswordHash: row.PasswordHash,
		Role:         row.Role,
	}, nil
}

func (r *AdminRepo) UpdatePassword(ctx context.Context, id uuid.UUID, hash string) error {
	return r.q.UpdateAdminPassword(ctx, sqlcdb.UpdateAdminPasswordParams{
		ID:           id,
		PasswordHash: hash,
	})
}
