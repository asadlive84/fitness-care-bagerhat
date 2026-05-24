package handlers

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"time"

	"github.com/asadlive84/fitness-care-bagerhat/internal/models"
	"github.com/asadlive84/fitness-care-bagerhat/internal/services"
	"github.com/asadlive84/fitness-care-bagerhat/internal/utils"
	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
)

type adminPlanSvc interface {
	CreatePlan(ctx context.Context, req services.CreatePlanRequest) (*models.PlanTemplate, error)
	ListPlans(ctx context.Context) ([]*models.PlanTemplate, error)
	ListPlansWithSubscribers(ctx context.Context, filter models.PlanListFilter) (*models.PlansListResponse, error)
	UpdatePlan(ctx context.Context, id uuid.UUID, req services.UpdatePlanRequest) (*models.PlanTemplate, error)
	DeletePlan(ctx context.Context, id uuid.UUID) error
}

// AdminPlanHandler holds HTTP handlers for plan-template management.
type AdminPlanHandler struct {
	svc adminPlanSvc
	log *slog.Logger
}

// NewAdminPlanHandler creates an AdminPlanHandler.
func NewAdminPlanHandler(svc *services.PlanService, log *slog.Logger) *AdminPlanHandler {
	return &AdminPlanHandler{svc: svc, log: log}
}

// NewAdminPlanHandlerWithSvc injects any adminPlanSvc — used in tests.
func NewAdminPlanHandlerWithSvc(svc adminPlanSvc, log *slog.Logger) *AdminPlanHandler {
	return &AdminPlanHandler{svc: svc, log: log}
}

// ── DTOs ──────────────────────────────────────────────────────────────────────

type createPlanReq struct {
	Name         string  `json:"name"          validate:"required,min=2,max=100"`
	DurationDays int32   `json:"duration_days" validate:"required,min=1,max=3650"`
	DefaultPrice float64 `json:"default_price" validate:"gt=0"` // price must be positive
	BillingType  string  `json:"billing_type"  validate:"omitempty,oneof=prepaid postpaid"`
}

type updatePlanReq struct {
	Name         string  `json:"name"          validate:"required,min=2,max=100"`
	DurationDays int32   `json:"duration_days" validate:"required,min=1,max=3650"`
	DefaultPrice float64 `json:"default_price" validate:"gt=0"`
	BillingType  string  `json:"billing_type"  validate:"omitempty,oneof=prepaid postpaid"`
}

// ── Handlers ──────────────────────────────────────────────────────────────────

// CreatePlan godoc
// @Summary     Create a plan template
// @Tags        admin/plans
// @Security    BearerAuth
// @Accept      json
// @Produce     json
// @Param       body body createPlanReq true "Plan details"
// @Success     201 {object} map[string]any
// @Router      /api/v1/admin/plans [post]
func (h *AdminPlanHandler) CreatePlan(c *fiber.Ctx) error {
	var req createPlanReq
	if !parseAndValidate(c, &req) {
		return nil
	}

	plan, err := h.svc.CreatePlan(c.UserContext(), services.CreatePlanRequest{
		Name:         req.Name,
		DurationDays: req.DurationDays,
		DefaultPrice: req.DefaultPrice,
		BillingType:  req.BillingType,
	})
	if err != nil {
		h.log.ErrorContext(c.UserContext(), "create plan", "error", err)
		return utils.ErrorResponse(c, fiber.StatusInternalServerError,
			"INTERNAL_ERROR", "Could not create plan", nil)
	}

	return utils.SuccessResponse(c, fiber.StatusCreated, plan)
}

// ListPlans godoc
// @Summary     List all plan templates
// @Tags        admin/plans
// @Security    BearerAuth
// @Produce     json
// @Success     200 {object} map[string]any
// @Router      /api/v1/admin/plans [get]
func (h *AdminPlanHandler) ListPlans(c *fiber.Ctx) error {
	filter, err := parsePlanListFilter(c)
	if err != nil {
		return utils.ErrorResponse(c, fiber.StatusBadRequest, "VALIDATION_ERROR", err.Error(), nil)
	}

	plans, err := h.svc.ListPlansWithSubscribers(c.UserContext(), filter)
	if err != nil {
		h.log.ErrorContext(c.UserContext(), "list plans", "error", err)
		return utils.ErrorResponse(c, fiber.StatusInternalServerError,
			"INTERNAL_ERROR", "Could not fetch plans", nil)
	}
	return utils.SuccessResponse(c, fiber.StatusOK, plans)
}

// parsePlanListFilter reads ?month=YYYY-MM or ?from=YYYY-MM-DD&to=YYYY-MM-DD.
// Returns a zero-value filter (lifetime) when no params are provided.
func parsePlanListFilter(c *fiber.Ctx) (models.PlanListFilter, error) {
	// ?month=YYYY-MM  →  from=first day, to=last day of that month
	if m := c.Query("month"); m != "" {
		t, err := time.Parse("2006-01", m)
		if err != nil {
			return models.PlanListFilter{}, fmt.Errorf("month must be YYYY-MM (e.g. 2026-04)")
		}
		from := t
		to := t.AddDate(0, 1, -1) // last day of the month
		return models.PlanListFilter{From: &from, To: &to}, nil
	}

	fromStr := c.Query("from")
	toStr := c.Query("to")

	// Both absent → lifetime
	if fromStr == "" && toStr == "" {
		return models.PlanListFilter{}, nil
	}

	var from, to time.Time
	var err error
	if fromStr != "" {
		from, err = time.Parse("2006-01-02", fromStr)
		if err != nil {
			return models.PlanListFilter{}, fmt.Errorf("from must be YYYY-MM-DD")
		}
	} else {
		// Default from to the beginning of the Unix epoch when only to is given
		from = time.Date(2000, 1, 1, 0, 0, 0, 0, time.UTC)
	}

	if toStr != "" {
		to, err = time.Parse("2006-01-02", toStr)
		if err != nil {
			return models.PlanListFilter{}, fmt.Errorf("to must be YYYY-MM-DD")
		}
	} else {
		to = time.Now().UTC()
	}

	if to.Before(from) {
		return models.PlanListFilter{}, fmt.Errorf("to must not be before from")
	}

	return models.PlanListFilter{From: &from, To: &to}, nil
}

// UpdatePlan godoc
// @Summary     Update a plan template
// @Tags        admin/plans
// @Security    BearerAuth
// @Accept      json
// @Produce     json
// @Param       id   path string       true "Plan UUID"
// @Param       body body updatePlanReq true "Updated fields"
// @Success     200 {object} map[string]any
// @Router      /api/v1/admin/plans/{id} [patch]
func (h *AdminPlanHandler) UpdatePlan(c *fiber.Ctx) error {
	id, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return utils.ErrorResponse(c, fiber.StatusBadRequest,
			"INVALID_ID", "Plan ID must be a valid UUID", nil)
	}

	var req updatePlanReq
	if !parseAndValidate(c, &req) {
		return nil
	}

	plan, err := h.svc.UpdatePlan(c.UserContext(), id, services.UpdatePlanRequest{
		Name:         req.Name,
		DurationDays: req.DurationDays,
		DefaultPrice: req.DefaultPrice,
		BillingType:  req.BillingType,
	})
	if err != nil {
		if errors.Is(err, services.ErrNotFound) {
			return utils.ErrorResponse(c, fiber.StatusNotFound, "NOT_FOUND", "Plan not found", nil)
		}
		h.log.ErrorContext(c.UserContext(), "update plan", "error", err)
		return utils.ErrorResponse(c, fiber.StatusInternalServerError, "INTERNAL_ERROR", "Update failed", nil)
	}

	return utils.SuccessResponse(c, fiber.StatusOK, plan)
}

// DeletePlan godoc
// @Summary     Delete a plan template
// @Tags        admin/plans
// @Security    BearerAuth
// @Param       id path string true "Plan UUID"
// @Success     204
// @Failure     404,409 {object} map[string]any
// @Router      /api/v1/admin/plans/{id} [delete]
func (h *AdminPlanHandler) DeletePlan(c *fiber.Ctx) error {
	id, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return utils.ErrorResponse(c, fiber.StatusBadRequest,
			"INVALID_ID", "Plan ID must be a valid UUID", nil)
	}

	if err := h.svc.DeletePlan(c.UserContext(), id); err != nil {
		switch {
		case errors.Is(err, services.ErrNotFound):
			return utils.ErrorResponse(c, fiber.StatusNotFound, "NOT_FOUND", "Plan not found", nil)
		case errors.Is(err, services.ErrConflict):
			return utils.ErrorResponse(c, fiber.StatusConflict, "CONFLICT",
				"Plan has active subscriptions and cannot be deleted", nil)
		default:
			h.log.ErrorContext(c.UserContext(), "delete plan", "error", err)
			return utils.ErrorResponse(c, fiber.StatusInternalServerError, "INTERNAL_ERROR", "Delete failed", nil)
		}
	}

	return c.SendStatus(fiber.StatusNoContent)
}

// PublicListPlans returns all active plan templates — no auth required.
// Used by the public landing page to display pricing.
func (h *AdminPlanHandler) PublicListPlans(c *fiber.Ctx) error {
	plans, err := h.svc.ListPlans(c.UserContext())
	if err != nil {
		h.log.ErrorContext(c.UserContext(), "public list plans", "error", err)
		return utils.ErrorResponse(c, fiber.StatusInternalServerError, "INTERNAL_ERROR", "Failed to load plans", nil)
	}
	return utils.SuccessResponse(c, fiber.StatusOK, plans)
}
