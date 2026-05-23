package main

import (
	"context"
	"log/slog"

	"github.com/asadlive84/fitness-care-bagerhat/internal/config"
	"github.com/asadlive84/fitness-care-bagerhat/internal/models"
	"github.com/asadlive84/fitness-care-bagerhat/internal/repositories"
	"github.com/google/uuid"
	"golang.org/x/crypto/bcrypt"
)

// seedSuperAdmin creates the superadmin account on startup if it does not
// already exist. Credentials are read from environment variables:
//
//	SUPERADMIN_EMAIL    (default: superadmin@fitnesscare.local)
//	SUPERADMIN_PASSWORD (default: ChangeMe@123 — change this in production)
//
// Existing records are never touched, so re-running is safe.
func seedSuperAdmin(ctx context.Context, admins repositories.AdminRepository, cfg *config.Config, log *slog.Logger) {
	email := cfg.SuperAdmin.Email
	if email == "" {
		email = "superadmin@fitnesscare.local"
	}
	password := cfg.SuperAdmin.Password
	if password == "" {
		password = "ChangeMe@123"
	}

	// Check if the superadmin already exists.
	existing, err := admins.GetByEmail(ctx, email)
	if err == nil && existing != nil {
		return // already seeded
	}

	hash, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		log.Error("superadmin seed: hash password", "error", err)
		return
	}

	sa := &models.Admin{
		ID:    uuid.New(),
		Name:  "Super Admin",
		Email: email,
	}

	if err := admins.CreateSuperAdmin(ctx, sa, string(hash)); err != nil {
		log.Error("superadmin seed: create", "error", err)
		return
	}

	log.Info("superadmin account seeded",
		slog.String("email", email),
		slog.String("note", "change the default password immediately"),
	)
}
