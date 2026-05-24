package handlers

import (
	"errors"
	"log/slog"
	"time"

	"github.com/asadlive84/fitness-care-bagerhat/internal/services"
	"github.com/asadlive84/fitness-care-bagerhat/internal/utils"
	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
)

// AuthHandler holds the HTTP handlers for auth endpoints.
type AuthHandler struct {
	authSvc   *services.AuthService
	memberSvc *services.MemberService
	log       *slog.Logger
}

// NewAuthHandler creates an AuthHandler.
func NewAuthHandler(authSvc *services.AuthService, log *slog.Logger) *AuthHandler {
	return &AuthHandler{authSvc: authSvc, log: log}
}

// NewAuthHandlerWithMemberSvc creates an AuthHandler that also handles self-registration.
func NewAuthHandlerWithMemberSvc(authSvc *services.AuthService, memberSvc *services.MemberService, log *slog.Logger) *AuthHandler {
	return &AuthHandler{authSvc: authSvc, memberSvc: memberSvc, log: log}
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

type registerMemberRequest struct {
	Name           string  `json:"name"            validate:"required,min=2,max=100"`
	Phone          string  `json:"phone"           validate:"required,min=10,max=15"`
	Email          *string `json:"email"`
	Gender         string  `json:"gender"          validate:"required,oneof=Male Female Other"`
	Religion       *string `json:"religion"`
	DateOfBirth    *string `json:"date_of_birth"`  // YYYY-MM-DD
	NID            *string `json:"nid"`
	PresentAddress *string `json:"present_address"`
	HeightCm       *float64 `json:"height_cm"`
	CurrentWeight  *float64 `json:"current_weight"`
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
		case errors.Is(err, services.ErrMemberPending):
			return utils.ErrorResponse(c, fiber.StatusForbidden,
				"ACCOUNT_PENDING", "Your registration is pending admin approval", nil)
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

// RegisterMember godoc
// @Summary     Self-registration
// @Tags        auth
// @Accept      json
// @Produce     json
// @Param       body body registerMemberRequest true "Registration details"
// @Success     201 {object} map[string]any
// @Failure     409 {object} map[string]any
// @Router      /api/v1/auth/register [post]
func (h *AuthHandler) RegisterMember(c *fiber.Ctx) error {
	if h.memberSvc == nil {
		return utils.ErrorResponse(c, fiber.StatusNotImplemented, "NOT_IMPLEMENTED", "Registration not configured", nil)
	}
	var req registerMemberRequest
	if !parseAndValidate(c, &req) {
		return nil
	}

	svcReq := services.RegisterMemberRequest{
		Name:           req.Name,
		Phone:          req.Phone,
		Email:          req.Email,
		Gender:         req.Gender,
		Religion:       req.Religion,
		NID:            req.NID,
		PresentAddress: req.PresentAddress,
		HeightCm:       req.HeightCm,
		CurrentWeight:  req.CurrentWeight,
	}
	if req.DateOfBirth != nil {
		t, err := time.Parse("2006-01-02", *req.DateOfBirth)
		if err != nil {
			return utils.ErrorResponse(c, fiber.StatusBadRequest, "BAD_REQUEST", "date_of_birth must be YYYY-MM-DD", nil)
		}
		svcReq.DateOfBirth = &t
	}

	member, err := h.memberSvc.RegisterMember(c.UserContext(), svcReq)
	if err != nil {
		if errors.Is(err, services.ErrConflict) {
			return utils.ErrorResponse(c, fiber.StatusConflict, "CONFLICT", "Phone number already registered", nil)
		}
		h.log.ErrorContext(c.UserContext(), "self-registration failed", "error", err)
		return utils.ErrorResponse(c, fiber.StatusInternalServerError, "INTERNAL_ERROR", "Registration failed", nil)
	}

	return utils.SuccessResponse(c, fiber.StatusCreated, fiber.Map{
		"id":      member.ID,
		"message": "Registration submitted, awaiting admin approval",
	})
}
