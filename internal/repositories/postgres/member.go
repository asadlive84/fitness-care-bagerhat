package postgres

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"

	sqlcdb "github.com/asadlive84/fitness-care-bagerhat/internal/database/sqlc"
	"github.com/asadlive84/fitness-care-bagerhat/internal/models"
	"github.com/google/uuid"
	"github.com/lib/pq"
)

// MemberRepo is a pure Postgres implementation — no cache awareness.
type MemberRepo struct {
	q  *sqlcdb.Queries
	db *sql.DB
}

func NewMemberRepo(db *sql.DB) *MemberRepo {
	return &MemberRepo{q: sqlcdb.New(db), db: db}
}

// memberSelectCols is the canonical column list used by all raw member SELECTs.
// password_hash is deliberately excluded — use GetMemberCredentials for auth.
const memberSelectCols = `
	id, name, phone, email, gender, goal, join_date,
	current_weight, height_cm, date_of_birth, religion, blood_group,
	hobbies, present_address, permanent_address, occupation, nid,
	emergency_phone, status, must_change_password, created_at, updated_at,
	budget_level, is_ai_allowed, is_ai_food_log_allowed, profile_picture_url, diet_chart_json, pending_diet_chart_json`

// scanMember scans a row produced by memberSelectCols into a *models.Member.
func scanMember(scan func(dest ...interface{}) error) (*models.Member, error) {
	var (
		goal                 sql.NullString
		currentWeight        sql.NullFloat64
		heightCm             sql.NullFloat64
		dateOfBirth          sql.NullTime
		religion             sql.NullString
		bloodGroup           sql.NullString
		hobbies              pq.StringArray
		presentAddress       sql.NullString
		permanentAddress     sql.NullString
		occupation           sql.NullString
		nidVal               sql.NullString
		emergencyPhone       sql.NullString
		budgetLevel          sql.NullString
		isAIAllowed          bool
		isAIFoodLogAllowed   bool
		profilePicUrl        sql.NullString
		dietChartJson        []byte
		pendingDietChartJson []byte
	)
	var emailVal sql.NullString
	m := &models.Member{}
	err := scan(
		&m.ID, &m.Name, &m.Phone, &emailVal, &m.Gender, &goal, &m.JoinDate,
		&currentWeight, &heightCm, &dateOfBirth, &religion, &bloodGroup,
		&hobbies, &presentAddress, &permanentAddress, &occupation, &nidVal,
		&emergencyPhone, &m.Status, &m.MustChangePassword, &m.CreatedAt, &m.UpdatedAt,
		&budgetLevel, &isAIAllowed, &isAIFoodLogAllowed, &profilePicUrl, &dietChartJson, &pendingDietChartJson,
	)
	if err != nil {
		return nil, err
	}
	if emailVal.Valid {
		m.Email = &emailVal.String
	}
	if goal.Valid {
		m.Goal = &goal.String
	}
	if currentWeight.Valid {
		m.CurrentWeight = &currentWeight.Float64
	}
	if heightCm.Valid {
		m.HeightCm = &heightCm.Float64
	}
	if dateOfBirth.Valid {
		m.DateOfBirth = &dateOfBirth.Time
	}
	if religion.Valid {
		m.Religion = &religion.String
	}
	if bloodGroup.Valid {
		m.BloodGroup = &bloodGroup.String
	}
	if len(hobbies) > 0 {
		m.Hobbies = []string(hobbies)
	}
	if presentAddress.Valid {
		m.PresentAddress = &presentAddress.String
	}
	if permanentAddress.Valid {
		m.PermanentAddress = &permanentAddress.String
	}
	if occupation.Valid {
		m.Occupation = &occupation.String
	}
	if nidVal.Valid {
		m.NID = &nidVal.String
	}
	if emergencyPhone.Valid {
		m.EmergencyPhone = &emergencyPhone.String
	}
	if budgetLevel.Valid {
		m.BudgetLevel = &budgetLevel.String
	}
	m.IsAIAllowed = isAIAllowed
	m.IsAIFoodLogAllowed = isAIFoodLogAllowed
	if profilePicUrl.Valid {
		m.ProfilePictureURL = &profilePicUrl.String
	}
	if len(dietChartJson) > 0 {
		raw := json.RawMessage(dietChartJson)
		m.DietChartJSON = &raw
	}
	if len(pendingDietChartJson) > 0 {
		raw := json.RawMessage(pendingDietChartJson)
		m.PendingDietChartJSON = &raw
	}
	return m, nil
}

// Create inserts a new member including all extended profile fields.
func (r *MemberRepo) Create(ctx context.Context, m *models.Member, passwordHash string) error {
	var dob interface{}
	if m.DateOfBirth != nil {
		dob = m.DateOfBirth.Format("2006-01-02")
	}
	_, err := r.db.ExecContext(ctx, `
		INSERT INTO members (
			id, name, phone, email, password_hash, gender, goal, join_date,
			current_weight, height_cm, date_of_birth, religion, blood_group,
			hobbies, present_address, permanent_address, occupation, nid,
			emergency_phone, status, must_change_password, created_by_admin_id,
			is_ai_allowed, is_ai_food_log_allowed
		) VALUES (
			$1,$2,$3,$4,$5,$6,$7,$8,
			$9,$10,$11,$12,$13,
			$14,$15,$16,$17,$18,
			$19,$20,$21,$22,
			$23,$24
		)`,
		m.ID, m.Name, m.Phone, nullString(m.Email), passwordHash, m.Gender, nullString(m.Goal), m.JoinDate,
		nullFloat64(m.CurrentWeight), nullFloat64(m.HeightCm), dob, nullString(m.Religion), nullString(m.BloodGroup),
		pq.Array(m.Hobbies), nullString(m.PresentAddress), nullString(m.PermanentAddress), nullString(m.Occupation), nullString(m.NID),
		nullString(m.EmergencyPhone), m.Status, m.MustChangePassword, nullUUID(m.CreatedByAdminID),
		m.IsAIAllowed, m.IsAIFoodLogAllowed,
	)
	return mapErr(err)
}

// GetByID returns a full member profile by primary key, including active subscription if any.
func (r *MemberRepo) GetByID(ctx context.Context, id uuid.UUID) (*models.Member, error) {
	row := r.db.QueryRowContext(ctx,
		`SELECT`+memberSelectCols+` FROM members WHERE id = $1 LIMIT 1`, id)
	m, err := scanMember(row.Scan)
	if err != nil {
		return nil, fmt.Errorf("get member by id: %w", mapErr(err))
	}
	return m, nil
}

// GetByPhone returns a full member profile by phone number.
func (r *MemberRepo) GetByPhone(ctx context.Context, phone string) (*models.Member, error) {
	row := r.db.QueryRowContext(ctx,
		`SELECT`+memberSelectCols+` FROM members WHERE phone = $1 LIMIT 1`, phone)
	m, err := scanMember(row.Scan)
	if err != nil {
		return nil, fmt.Errorf("get member by phone: %w", mapErr(err))
	}
	return m, nil
}

// GetMemberCredentials uses sqlc (which includes password_hash) — never cached.
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

// Update saves profile changes including all extended fields.
func (r *MemberRepo) Update(ctx context.Context, m *models.Member) error {
	var dob interface{}
	if m.DateOfBirth != nil {
		dob = m.DateOfBirth.Format("2006-01-02")
	}
	_, err := r.db.ExecContext(ctx, `
		UPDATE members SET
			name              = $1,
			phone             = $2,
			gender            = $3,
			goal              = $4,
			current_weight    = $5,
			height_cm         = $6,
			date_of_birth     = $7,
			religion          = $8,
			blood_group       = $9,
			hobbies           = $10,
			present_address   = $11,
			permanent_address = $12,
			occupation        = $13,
			nid               = $14,
			emergency_phone   = $15,
			updated_at        = NOW()
		WHERE id = $16`,
		m.Name, m.Phone, m.Gender, nullString(m.Goal), nullFloat64(m.CurrentWeight), nullFloat64(m.HeightCm),
		dob, nullString(m.Religion), nullString(m.BloodGroup), pq.Array(m.Hobbies),
		nullString(m.PresentAddress), nullString(m.PermanentAddress), nullString(m.Occupation),
		nullString(m.NID), nullString(m.EmergencyPhone), m.ID,
	)
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

// ResetPasswordByAdmin stores a new bcrypt hash and sets must_change_password = TRUE,
// forcing the member to change on next login.
func (r *MemberRepo) ResetPasswordByAdmin(ctx context.Context, id uuid.UUID, hash string) error {
	_, err := r.db.ExecContext(ctx, `
		UPDATE members
		SET password_hash        = $1,
		    must_change_password = TRUE,
		    updated_at           = NOW()
		WHERE id = $2`, hash, id)
	return mapErr(err)
}

// List returns a paginated list using sqlc (basic columns only — sufficient for list views).
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

func (r *MemberRepo) ListExpiringSoon(ctx context.Context, _ int) ([]*models.Member, error) {
	rows, err := r.q.ListMembersWithExpiringSoon(ctx)
	if err != nil {
		return nil, fmt.Errorf("list expiring members: %w", err)
	}
	members := make([]*models.Member, len(rows))
	for i, row := range rows {
		members[i] = mapMember(row)
	}
	return members, nil
}

// Delete permanently removes a member and all their data in a single transaction.
func (r *MemberRepo) Delete(ctx context.Context, id uuid.UUID) error {
	tx, err := r.db.BeginTx(ctx, nil)
	if err != nil {
		return fmt.Errorf("begin tx: %w", err)
	}
	defer tx.Rollback() //nolint:errcheck

	for _, q := range []string{
		`DELETE FROM notifications  WHERE member_id = $1`,
		`DELETE FROM fcm_tokens     WHERE member_id = $1`,
		`DELETE FROM weight_logs    WHERE member_id = $1`,
		`DELETE FROM workout_logs   WHERE member_id = $1`,
		`DELETE FROM diet_logs      WHERE member_id = $1`,
		`DELETE FROM messages       WHERE sender_id = $1 OR receiver_id = $1`,
		`DELETE FROM payments       WHERE member_id = $1`,
		`DELETE FROM subscriptions  WHERE member_id = $1`,
		`DELETE FROM members        WHERE id        = $1`,
	} {
		if _, err := tx.ExecContext(ctx, q, id); err != nil {
			return fmt.Errorf("delete member: %w", mapErr(err))
		}
	}
	return tx.Commit()
}

func (r *MemberRepo) InvalidateCache(ctx context.Context, id uuid.UUID, phone string) error {
	return nil
}
