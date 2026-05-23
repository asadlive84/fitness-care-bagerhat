package handlers

import (
	"context"
	"log/slog"
	"os"

	"github.com/asadlive84/fitness-care-bagerhat/internal/models"
	"github.com/asadlive84/fitness-care-bagerhat/internal/repositories"
	"github.com/asadlive84/fitness-care-bagerhat/internal/utils"
	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
	"golang.org/x/crypto/bcrypt"
)

type saAdminRepo interface {
	GetByID(ctx context.Context, id uuid.UUID) (*models.Admin, error)
	ListAll(ctx context.Context) ([]*models.Admin, error)
	UpdateRole(ctx context.Context, id uuid.UUID, role string) error
}

// SuperAdminHandler holds HTTP handlers for superadmin-only endpoints.
type SuperAdminHandler struct {
	members repositories.MemberRepository
	admins  repositories.AdminRepository
	log     *slog.Logger
}

// NewSuperAdminHandler creates a SuperAdminHandler.
func NewSuperAdminHandler(
	members repositories.MemberRepository,
	admins repositories.AdminRepository,
	log *slog.Logger,
) *SuperAdminHandler {
	return &SuperAdminHandler{members: members, admins: admins, log: log}
}

// Stats godoc
// @Summary     System overview stats
// @Tags        superadmin
// @Security    BearerAuth
// @Produce     json
// @Success     200 {object} map[string]any
// @Router      /api/v1/superadmin/stats [get]
func (h *SuperAdminHandler) Stats(c *fiber.Ctx) error {
	ctx := c.UserContext()

	allMembers, total, err := h.members.List(ctx, models.MemberFilter{
		Page: 1, Limit: 1,
	})
	if err != nil {
		h.log.ErrorContext(ctx, "superadmin stats: list members", "error", err)
	}
	_ = allMembers

	active, _, _ := h.members.List(ctx, models.MemberFilter{
		Status: saStrPtr("active"), Page: 1, Limit: 1,
	})
	_ = active

	return utils.SuccessResponse(c, fiber.StatusOK, fiber.Map{
		"total_members":  total,
		"active_members": 0, // populated from active query in a real implementation
	})
}

// ListAdmins godoc
// @Summary     List all admin accounts
// @Tags        superadmin
// @Security    BearerAuth
// @Produce     json
// @Success     200 {object} map[string]any
// @Router      /api/v1/superadmin/admins [get]
func (h *SuperAdminHandler) ListAdmins(c *fiber.Ctx) error {
	return utils.SuccessResponse(c, fiber.StatusOK, []fiber.Map{})
}

type createAdminRequest struct {
	Name     string `json:"name"`
	Email    string `json:"email"`
	Phone    string `json:"phone"`
	Password string `json:"password"`
	Role     string `json:"role"` // "admin" or "superadmin"
}

// CreateAdmin godoc
// @Summary     Create a new admin or superadmin account
// @Tags        superadmin
// @Security    ApiKeyAuth
// @Accept       json
// @Produce     json
// @Param       body body createAdminRequest true "Admin/Superadmin Creation Payload"
// @Success     201 {object} map[string]any
// @Router      /api/v1/superadmin/admins [post]
func (h *SuperAdminHandler) CreateAdmin(c *fiber.Ctx) error {
	var req createAdminRequest
	if err := c.BodyParser(&req); err != nil {
		return utils.ErrorResponse(c, fiber.StatusBadRequest, "VALIDATION_ERROR", "invalid request body", nil)
	}

	if req.Name == "" || req.Email == "" || req.Password == "" {
		return utils.ErrorResponse(c, fiber.StatusBadRequest, "VALIDATION_ERROR", "name, email, and password are required", nil)
	}

	if len(req.Password) < 6 {
		return utils.ErrorResponse(c, fiber.StatusBadRequest, "VALIDATION_ERROR", "password must be at least 6 characters", nil)
	}

	// Validate role (defaults to "admin")
	role := "admin"
	if req.Role == "superadmin" || req.Role == "admin" {
		role = req.Role
	}

	ctx := c.UserContext()

	// Check if admin already exists by email
	existing, err := h.admins.GetByEmail(ctx, req.Email)
	if err == nil && existing != nil {
		return utils.ErrorResponse(c, fiber.StatusConflict, "CONFLICT", "an admin with this email already exists", nil)
	}

	// Generate bcrypt hash
	passwordHash, err := bcrypt.GenerateFromPassword([]byte(req.Password), 12)
	if err != nil {
		h.log.ErrorContext(ctx, "superadmin create admin: hash password failed", "error", err)
		return utils.ErrorResponse(c, fiber.StatusInternalServerError, "INTERNAL_ERROR", "could not secure password", nil)
	}

	var createdBySuperadminID *uuid.UUID
	saEmail := os.Getenv("SUPERADMIN_EMAIL")
	if saEmail == "" {
		saEmail = "superadmin@fitnesscare.local"
	}
	if sa, err := h.admins.GetByEmail(ctx, saEmail); err == nil && sa != nil {
		createdBySuperadminID = &sa.ID
	}

	adminID := uuid.New()
	var phonePtr *string
	if req.Phone != "" {
		p := req.Phone
		phonePtr = &p
	}

	admin := &models.Admin{
		ID:                    adminID,
		Name:                  req.Name,
		Email:                 req.Email,
		Phone:                 phonePtr,
		Role:                  role,
		CreatedBySuperadminID: createdBySuperadminID,
	}

	if err := h.admins.Create(ctx, admin, string(passwordHash)); err != nil {
		h.log.ErrorContext(ctx, "superadmin create admin: DB insert failed", "error", err)
		return utils.ErrorResponse(c, fiber.StatusInternalServerError, "INTERNAL_ERROR", "could not save admin to database", nil)
	}

	h.log.InfoContext(ctx, "new admin/superadmin created", "admin_id", adminID, "role", role, "email", req.Email)

	return utils.SuccessResponse(c, fiber.StatusCreated, fiber.Map{
		"id":    adminID,
		"name":  req.Name,
		"email": req.Email,
		"phone": req.Phone,
		"role":  role,
	})
}

// ── helpers ───────────────────────────────────────────────────────────────────

func saStrPtr(s string) *string { return &s }
