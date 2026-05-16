package handlers

import (
	"errors"
	"log/slog"

	"github.com/asadlive84/fitness-care-bagerhat/internal/services"
	"github.com/asadlive84/fitness-care-bagerhat/internal/utils"
	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
)

// AuthHandler holds the HTTP handlers for auth endpoints.
type AuthHandler struct {
	authSvc *services.AuthService
	log     *slog.Logger
}

// NewAuthHandler creates an AuthHandler.
func NewAuthHandler(authSvc *services.AuthService, log *slog.Logger) *AuthHandler {
	return &AuthHandler{authSvc: authSvc, log: log}
}

// ── Request / Response DTOs ───────────────────────────────────────────────────

type adminLoginRequest struct {
	Email    string `json:"email"    validate:"required,email"`
	Password string `json:"password" validate:"required,min=6"`
}

type memberLoginRequest struct {
	Phone    string `json:"phone"    validate:"required,min=10,max=15"`
	Password string `json:"password" validate:"required,min=6"`
}

type refreshRequest struct {
	RefreshToken string `json:"refresh_token" validate:"required"`
}

type changePasswordRequest struct {
	CurrentPassword string `json:"current_password" validate:"required,min=6"`
	NewPassword     string `json:"new_password"     validate:"required,min=8"`
}

// ── Handlers ──────────────────────────────────────────────────────────────────

// AdminLogin godoc
// @Summary     Admin login
// @Tags        auth
// @Accept      json
// @Produce     json
// @Param       body body adminLoginRequest true "Credentials"
// @Success     200 {object} map[string]any
// @Failure     401 {object} map[string]any
// @Router      /api/v1/auth/admin/login [post]
func (h *AuthHandler) AdminLogin(c *fiber.Ctx) error {
	var req adminLoginRequest
	if !parseAndValidate(c, &req) { // response already written
		return nil
	}

	pair, err := h.authSvc.LoginAdmin(c.UserContext(), req.Email, req.Password)
	if err != nil {
		if errors.Is(err, services.ErrInvalidCredentials) {
			return utils.ErrorResponse(c, fiber.StatusUnauthorized,
				"INVALID_CREDENTIALS", "Email or password is incorrect", nil)
		}
		h.log.ErrorContext(c.UserContext(), "admin login failed", "error", err)
		return utils.ErrorResponse(c, fiber.StatusInternalServerError,
			"INTERNAL_ERROR", "Login failed", nil)
	}

	return utils.SuccessResponse(c, fiber.StatusOK, pair)
}

// MemberLogin godoc
// @Summary     Member login
// @Tags        auth
// @Accept      json
// @Produce     json
// @Param       body body memberLoginRequest true "Credentials"
// @Success     200 {object} map[string]any
// @Failure     401 {object} map[string]any
// @Router      /api/v1/auth/member/login [post]
func (h *AuthHandler) MemberLogin(c *fiber.Ctx) error {
	var req memberLoginRequest
	if !parseAndValidate(c, &req) { // response already written
		return nil
	}

	result, err := h.authSvc.LoginMember(c.UserContext(), req.Phone, req.Password)
	if err != nil {
		switch {
		case errors.Is(err, services.ErrInvalidCredentials):
			return utils.ErrorResponse(c, fiber.StatusUnauthorized,
				"INVALID_CREDENTIALS", "Phone number or password is incorrect", nil)
		case errors.Is(err, services.ErrMemberInactive):
			return utils.ErrorResponse(c, fiber.StatusForbidden,
				"ACCOUNT_INACTIVE", "Your account has been deactivated", nil)
		default:
			h.log.ErrorContext(c.UserContext(), "member login failed", "error", err)
			return utils.ErrorResponse(c, fiber.StatusInternalServerError,
				"INTERNAL_ERROR", "Login failed", nil)
		}
	}

	return utils.SuccessResponse(c, fiber.StatusOK, result)
}

// RefreshToken godoc
// @Summary     Refresh access token
// @Tags        auth
// @Accept      json
// @Produce     json
// @Param       body body refreshRequest true "Refresh token"
// @Success     200 {object} map[string]any
// @Failure     401 {object} map[string]any
// @Router      /api/v1/auth/refresh [post]
func (h *AuthHandler) RefreshToken(c *fiber.Ctx) error {
	var req refreshRequest
	if !parseAndValidate(c, &req) { // response already written
		return nil
	}

	pair, err := h.authSvc.RefreshToken(c.UserContext(), req.RefreshToken)
	if err != nil {
		return utils.ErrorResponse(c, fiber.StatusUnauthorized,
			"INVALID_TOKEN", "Refresh token is invalid or expired", nil)
	}

	return utils.SuccessResponse(c, fiber.StatusOK, pair)
}

// ChangePassword godoc
// @Summary     Change member password
// @Tags        auth
// @Security    BearerAuth
// @Accept      json
// @Produce     json
// @Param       body body changePasswordRequest true "Passwords"
// @Success     204
// @Failure     401 {object} map[string]any
// @Router      /api/v1/auth/change-password [post]
func (h *AuthHandler) ChangePassword(c *fiber.Ctx) error {
	var req changePasswordRequest
	if !parseAndValidate(c, &req) { // response already written
		return nil
	}

	memberID, err := uuid.Parse(c.Locals("user_id").(string))
	if err != nil {
		return utils.ErrorResponse(c, fiber.StatusUnauthorized,
			"UNAUTHORIZED", "Invalid token payload", nil)
	}

	if err := h.authSvc.ChangeMemberPassword(
		c.UserContext(), memberID, req.CurrentPassword, req.NewPassword,
	); err != nil {
		if errors.Is(err, services.ErrInvalidCredentials) {
			return utils.ErrorResponse(c, fiber.StatusUnauthorized,
				"INVALID_CREDENTIALS", "Current password is incorrect", nil)
		}
		h.log.ErrorContext(c.UserContext(), "change password failed", "error", err)
		return utils.ErrorResponse(c, fiber.StatusInternalServerError,
			"INTERNAL_ERROR", "Password change failed", nil)
	}

	return c.SendStatus(fiber.StatusNoContent)
}
