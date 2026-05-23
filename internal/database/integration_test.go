package database_test

import (
	"context"
	"testing"
	"time"

	"github.com/asadlive84/fitness-care-bagerhat/internal/database/sqlc"
	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// TestMigrationAndAdminCRUD is the Step-2 critical-path test.
// It applies the migration against a real Postgres instance, then exercises
// the generated sqlc queries for the admins table.
func TestMigrationAndAdminCRUD(t *testing.T) {
	dsn := testDSN(t)     // skips if DATABASE_TEST_DSN unset
	db := openAndMigrate(t, dsn)

	q := sqlcdb.New(db)
	ctx := context.Background()

	// ── Create ───────────────────────────────────────────────────────────────
	adminID := uuid.New()
	created, err := q.CreateAdmin(ctx, sqlcdb.CreateAdminParams{
		ID:           adminID,
		Name:         "Gym Owner",
		Email:        "owner@fitnesscare.bd",
		PasswordHash: "$2a$12$test_hash_placeholder",
	})
	require.NoError(t, err)
	assert.Equal(t, adminID, created.ID)
	assert.Equal(t, "Gym Owner", created.Name)
	assert.Equal(t, "owner@fitnesscare.bd", created.Email)

	// ── Read by ID ────────────────────────────────────────────────────────────
	fetched, err := q.GetAdminByID(ctx, adminID)
	require.NoError(t, err)
	assert.Equal(t, adminID, fetched.ID)

	// ── Read by Email ─────────────────────────────────────────────────────────
	byEmail, err := q.GetAdminByEmail(ctx, "owner@fitnesscare.bd")
	require.NoError(t, err)
	assert.Equal(t, adminID, byEmail.ID)

	// ── Update password ───────────────────────────────────────────────────────
	err = q.UpdateAdminPassword(ctx, sqlcdb.UpdateAdminPasswordParams{
		ID:           adminID,
		PasswordHash: "$2a$12$new_hash_placeholder",
	})
	require.NoError(t, err)

	updated, err := q.GetAdminByID(ctx, adminID)
	require.NoError(t, err)
	assert.Equal(t, "$2a$12$new_hash_placeholder", updated.PasswordHash)
	assert.True(t, updated.UpdatedAt.After(updated.CreatedAt) || updated.UpdatedAt.Equal(updated.CreatedAt))

	// ── Timestamps are populated ──────────────────────────────────────────────
	assert.WithinDuration(t, time.Now(), created.CreatedAt, 5*time.Second)
}

// TestMigrationMemberAndPlan tests member + plan creation, covering FK constraints.
func TestMigrationMemberAndPlan(t *testing.T) {
	dsn := testDSN(t)
	db := openAndMigrate(t, dsn)

	q := sqlcdb.New(db)
	ctx := context.Background()

	// Create member
	memberID := uuid.New()
	member, err := q.CreateMember(ctx, sqlcdb.CreateMemberParams{
		ID:                 memberID,
		Name:               "Karim Ahmed",
		Phone:              "01711000001",
		PasswordHash:       "$2a$12$hash",
		Status:             "active",
		MustChangePassword: true,
		JoinDate:           time.Now(),
	})
	require.NoError(t, err)
	assert.Equal(t, "Karim Ahmed", member.Name)
	assert.Equal(t, "active", member.Status)

	// Retrieve by phone
	byPhone, err := q.GetMemberByPhone(ctx, "01711000001")
	require.NoError(t, err)
	assert.Equal(t, memberID, byPhone.ID)

	// Create plan template
	planID := uuid.New()
	plan, err := q.CreatePlanTemplate(ctx, sqlcdb.CreatePlanTemplateParams{
		ID:           planID,
		Name:         "Monthly Basic",
		DurationDays: 30,
		DefaultPrice: 1500,
	})
	require.NoError(t, err)
	assert.Equal(t, float64(1500), plan.DefaultPrice)

	// List plans — should have at least one
	plans, err := q.ListPlanTemplates(ctx)
	require.NoError(t, err)
	assert.GreaterOrEqual(t, len(plans), 1)

	// Default settings were seeded by the migration
	settings, err := q.GetAllSettings(ctx, uuid.NullUUID{})
	require.NoError(t, err)
	assert.GreaterOrEqual(t, len(settings), 3, "migration should seed 3 default settings")
}
