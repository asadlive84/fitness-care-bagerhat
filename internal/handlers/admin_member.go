package handlers

import (
	"context"
	"errors"
	"log/slog"
	"time"

	"github.com/asadlive84/fitness-care-bagerhat/internal/models"
	"github.com/asadlive84/fitness-care-bagerhat/internal/services"
	"github.com/asadlive84/fitness-care-bagerhat/internal/utils"
	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
)

// adminMemberSvc is the thin service interface the handler depends on.
// Defined in the consumer package per the project's interface convention.
type adminMemberSvc interface {
	CreateMember(ctx context.Context, req services.CreateMemberRequest) (*services.CreateMemberResult, error)
	GetMember(ctx context.Context, id uuid.UUID) (*models.Member, error)
	ListMembers(ctx context.Context, f models.MemberFilter) ([]*models.Member, int64, error)
	ListExpiringSoon(ctx context.Context) ([]*models.Member, error)
	UpdateMember(ctx context.Context, id uuid.UUID, req services.UpdateMemberRequest) (*models.Member, error)
	UpdateMemberStatus(ctx context.Context, id uuid.UUID, status string) error
}

// AdminMemberHandler holds HTTP handlers for admin member management.
type AdminMemberHandler struct {
	svc adminMemberSvc
	log *slog.Logger
}

// NewAdminMemberHandler creates an AdminMemberHandler backed by the concrete service.
func NewAdminMemberHandler(svc *services.MemberService, log *slog.Logger) *AdminMemberHandler {
	return &AdminMemberHandler{svc: svc, log: log}
}

// NewAdminMemberHandlerWithSvc creates an AdminMemberHandler with any adminMemberSvc
// implementation — used in tests to inject fakes.
func NewAdminMemberHandlerWithSvc(svc adminMemberSvc, log *slog.Logger) *AdminMemberHandler {
	return &AdminMemberHandler{svc: svc, log: log}
}

// ── Request DTOs ──────────────────────────────────────────────────────────────

type createMemberReq struct {
	Name          string   `json:"name"           validate:"required,min=2,max=100"`
	Phone         string   `json:"phone"          validate:"required,min=10,max=15"`
	Goal          *string  `json:"goal"`
	CurrentWeight *float64 `json:"current_weight"`
	JoinDate      *string  `json:"join_date"` // optional, YYYY-MM-DD
}

type updateMemberReq struct {
	Name          string   `json:"name"           validate:"required,min=2,max=100"`
	Phone         string   `json:"phone"          validate:"required,min=10,max=15"`
	Goal          *string  `json:"goal"`
	CurrentWeight *float64 `json:"current_weight"`
}

type updateStatusReq struct {
	Status string `json:"status" validate:"required,oneof=active inactive"`
}

// ── Handlers ──────────────────────────────────────────────────────────────────

// CreateMember godoc
// @Summary     Create a new member
// @Tags        admin/members
// @Security    BearerAuth
// @Accept      json
// @Produce     json
// @Param       body body createMemberReq true "Member details"
// @Success     201 {object} map[string]any
// @Router      /api/v1/admin/members [post]
func (h *AdminMemberHandler) CreateMember(c *fiber.Ctx) error {
	var req createMemberReq
	if !parseAndValidate(c, &req) { // response already written
		return nil
	}

	svcReq := services.CreateMemberRequest{
		Name:          req.Name,
		Phone:         req.Phone,
		Goal:          req.Goal,
		CurrentWeight: req.CurrentWeight,
	}
	if req.JoinDate != nil {
		t, err := parseDate(*req.JoinDate)
		if err != nil {
			return utils.ErrorResponse(c, fiber.StatusBadRequest,
				"VALIDATION_ERROR", "join_date must be YYYY-MM-DD", nil)
		}
		svcReq.JoinDate = t
	}

	result, err := h.svc.CreateMember(c.UserContext(), svcReq)
	if err != nil {
		if errors.Is(err, services.ErrConflict) {
			return utils.ErrorResponse(c, fiber.StatusConflict,
				"CONFLICT", "Phone number is already registered", nil)
		}
		h.log.ErrorContext(c.UserContext(), "create member", "error", err)
		return utils.ErrorResponse(c, fiber.StatusInternalServerError,
			"INTERNAL_ERROR", "Could not create member", nil)
	}

	return utils.SuccessResponse(c, fiber.StatusCreated, result)
}

// ListMembers godoc
// @Summary     List members (paginated, filterable)
// @Tags        admin/members
// @Security    BearerAuth
// @Produce     json
// @Param       page          query int    false "Page (default 1)"
// @Param       limit         query int    false "Limit (default 20, max 100)"
// @Param       status        query string false "active|inactive"
// @Param       search        query string false "Name or phone search"
// @Param       expiring_soon query bool   false "Only members with expiring subscription"
// @Success     200 {object} map[string]any
// @Router      /api/v1/admin/members [get]
func (h *AdminMemberHandler) ListMembers(c *fiber.Ctx) error {
	page, limit := parsePagination(c)

	if c.QueryBool("expiring_soon", false) {
		members, err := h.svc.ListExpiringSoon(c.UserContext())
		if err != nil {
			h.log.ErrorContext(c.UserContext(), "list expiring members", "error", err)
			return utils.ErrorResponse(c, fiber.StatusInternalServerError,
				"INTERNAL_ERROR", "Could not fetch expiring members", nil)
		}
		return utils.PaginatedResponse(c, members, 1, len(members), len(members))
	}

	var status *string
	if s := c.Query("status"); s != "" {
		status = &s
	}
	var search *string
	if s := c.Query("search"); s != "" {
		search = &s
	}

	members, total, err := h.svc.ListMembers(c.UserContext(), models.MemberFilter{
		Status: status,
		Search: search,
		Page:   page,
		Limit:  limit,
	})
	if err != nil {
		h.log.ErrorContext(c.UserContext(), "list members", "error", err)
		return utils.ErrorResponse(c, fiber.StatusInternalServerError,
			"INTERNAL_ERROR", "Could not fetch members", nil)
	}

	return utils.PaginatedResponse(c, members, page, limit, int(total))
}

// GetMember godoc
// @Summary     Get a member by ID
// @Tags        admin/members
// @Security    BearerAuth
// @Produce     json
// @Param       id path string true "Member UUID"
// @Success     200 {object} map[string]any
// @Failure     404 {object} map[string]any
// @Router      /api/v1/admin/members/{id} [get]
func (h *AdminMemberHandler) GetMember(c *fiber.Ctx) error {
	id, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return utils.ErrorResponse(c, fiber.StatusBadRequest,
			"INVALID_ID", "Member ID must be a valid UUID", nil)
	}

	member, err := h.svc.GetMember(c.UserContext(), id)
	if err != nil {
		if errors.Is(err, services.ErrNotFound) {
			return utils.ErrorResponse(c, fiber.StatusNotFound,
				"NOT_FOUND", "Member not found", nil)
		}
		h.log.ErrorContext(c.UserContext(), "get member", "error", err)
		return utils.ErrorResponse(c, fiber.StatusInternalServerError,
			"INTERNAL_ERROR", "Could not fetch member", nil)
	}

	return utils.SuccessResponse(c, fiber.StatusOK, member)
}

// UpdateMember godoc
// @Summary     Update member profile
// @Tags        admin/members
// @Security    BearerAuth
// @Accept      json
// @Produce     json
// @Param       id   path string         true "Member UUID"
// @Param       body body updateMemberReq true "Updated fields"
// @Success     200 {object} map[string]any
// @Router      /api/v1/admin/members/{id} [patch]
func (h *AdminMemberHandler) UpdateMember(c *fiber.Ctx) error {
	id, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return utils.ErrorResponse(c, fiber.StatusBadRequest,
			"INVALID_ID", "Member ID must be a valid UUID", nil)
	}

	var req updateMemberReq
	if !parseAndValidate(c, &req) { // response already written
		return nil
	}

	member, err := h.svc.UpdateMember(c.UserContext(), id, services.UpdateMemberRequest{
		Name:          req.Name,
		Phone:         req.Phone,
		Goal:          req.Goal,
		CurrentWeight: req.CurrentWeight,
	})
	if err != nil {
		switch {
		case errors.Is(err, services.ErrNotFound):
			return utils.ErrorResponse(c, fiber.StatusNotFound, "NOT_FOUND", "Member not found", nil)
		case errors.Is(err, services.ErrConflict):
			return utils.ErrorResponse(c, fiber.StatusConflict, "CONFLICT", "Phone already registered", nil)
		default:
			h.log.ErrorContext(c.UserContext(), "update member", "error", err)
			return utils.ErrorResponse(c, fiber.StatusInternalServerError, "INTERNAL_ERROR", "Update failed", nil)
		}
	}

	return utils.SuccessResponse(c, fiber.StatusOK, member)
}

// UpdateMemberStatus godoc
// @Summary     Set member active/inactive
// @Tags        admin/members
// @Security    BearerAuth
// @Accept      json
// @Produce     json
// @Param       id   path string         true "Member UUID"
// @Param       body body updateStatusReq true "New status"
// @Success     204
// @Router      /api/v1/admin/members/{id}/status [patch]
func (h *AdminMemberHandler) UpdateMemberStatus(c *fiber.Ctx) error {
	id, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return utils.ErrorResponse(c, fiber.StatusBadRequest,
			"INVALID_ID", "Member ID must be a valid UUID", nil)
	}

	var req updateStatusReq
	if !parseAndValidate(c, &req) { // response already written
		return nil
	}

	if err := h.svc.UpdateMemberStatus(c.UserContext(), id, req.Status); err != nil {
		if errors.Is(err, services.ErrNotFound) {
			return utils.ErrorResponse(c, fiber.StatusNotFound, "NOT_FOUND", "Member not found", nil)
		}
		h.log.ErrorContext(c.UserContext(), "update member status", "error", err)
		return utils.ErrorResponse(c, fiber.StatusInternalServerError, "INTERNAL_ERROR", "Status update failed", nil)
	}

	return c.SendStatus(fiber.StatusNoContent)
}

// ── shared helpers ────────────────────────────────────────────────────────────

func parsePagination(c *fiber.Ctx) (page, limit int) {
	page = c.QueryInt("page", 1)
	limit = c.QueryInt("limit", 20)
	if page < 1 {
		page = 1
	}
	if limit < 1 || limit > 100 {
		limit = 20
	}
	return
}

func parseDate(s string) (time.Time, error) {
	return time.Parse("2006-01-02", s)
}
