package handlers

import (
	"context"
	"errors"
	"log/slog"

	"github.com/asadlive84/fitness-care-bagerhat/internal/models"
	"github.com/asadlive84/fitness-care-bagerhat/internal/services"
	"github.com/asadlive84/fitness-care-bagerhat/internal/utils"
	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
)

type adminSubSvc interface {
	AssignPlan(ctx context.Context, memberID uuid.UUID, req services.AssignPlanRequest) (*models.Subscription, error)
	ListSubscriptions(ctx context.Context, memberID uuid.UUID) ([]*models.Subscription, error)
	UpdateActive(ctx context.Context, memberID uuid.UUID, req services.UpdateActiveRequest) (*models.Subscription, error)
}

// AdminSubscriptionHandler holds HTTP handlers for subscription management.
type AdminSubscriptionHandler struct {
	svc adminSubSvc
	log *slog.Logger
}

// NewAdminSubscriptionHandler creates an AdminSubscriptionHandler.
func NewAdminSubscriptionHandler(svc *services.SubscriptionService, log *slog.Logger) *AdminSubscriptionHandler {
	return &AdminSubscriptionHandler{svc: svc, log: log}
}

// NewAdminSubscriptionHandlerWithSvc injects any adminSubSvc — used in tests.
func NewAdminSubscriptionHandlerWithSvc(svc adminSubSvc, log *slog.Logger) *AdminSubscriptionHandler {
	return &AdminSubscriptionHandler{svc: svc, log: log}
}

// ── DTOs ──────────────────────────────────────────────────────────────────────

type assignPlanReq struct {
	PlanTemplateID      string   `json:"plan_template_id" validate:"required,uuid"`
	StartDate           *string  `json:"start_date"`    // YYYY-MM-DD, optional
	FinalPrice          *float64 `json:"final_price"`   // optional; defaults to plan price
	Note                *string  `json:"note"`
	BillingType         string   `json:"billing_type"           validate:"omitempty,oneof=prepaid postpaid"`
	PrepaidDueDate      *string  `json:"prepaid_due_date"`       // YYYY-MM-DD
	PostpaidGraceBefore *int     `json:"postpaid_grace_before"`
	PostpaidGraceAfter  *int     `json:"postpaid_grace_after"`
}

type updateActiveReq struct {
	StartDate           string   `json:"start_date"  validate:"required"`
	EndDate             string   `json:"end_date"    validate:"required"`
	FinalPrice          float64  `json:"final_price" validate:"min=0"` // 0 allowed (e.g. free extension)
	Note                *string  `json:"note"`
	BillingType         string   `json:"billing_type"           validate:"omitempty,oneof=prepaid postpaid"`
	PrepaidDueDate      *string  `json:"prepaid_due_date"`
	PostpaidGraceBefore *int     `json:"postpaid_grace_before"`
	PostpaidGraceAfter  *int     `json:"postpaid_grace_after"`
}

// ── Handlers ──────────────────────────────────────────────────────────────────

// AssignPlan godoc
// @Summary     Assign a plan to a member
// @Tags        admin/subscriptions
// @Security    BearerAuth
// @Accept      json
// @Produce     json
// @Param       id   path string       true "Member UUID"
// @Param       body body assignPlanReq true "Subscription details"
// @Success     201 {object} map[string]any
// @Router      /api/v1/admin/members/{id}/subscriptions [post]
func (h *AdminSubscriptionHandler) AssignPlan(c *fiber.Ctx) error {
	memberID, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return utils.ErrorResponse(c, fiber.StatusBadRequest,
			"INVALID_ID", "Member ID must be a valid UUID", nil)
	}

	var req assignPlanReq
	if !parseAndValidate(c, &req) {
		return nil
	}

	planID, _ := uuid.Parse(req.PlanTemplateID) // validate tag already ensured this is a uuid

	svcReq := services.AssignPlanRequest{
		PlanTemplateID:      planID,
		FinalPrice:          req.FinalPrice,
		Note:                req.Note,
		BillingType:         req.BillingType,
		PostpaidGraceBefore: req.PostpaidGraceBefore,
		PostpaidGraceAfter:  req.PostpaidGraceAfter,
	}
	if req.StartDate != nil {
		t, err := parseDate(*req.StartDate)
		if err != nil {
			return utils.ErrorResponse(c, fiber.StatusBadRequest,
				"VALIDATION_ERROR", "start_date must be YYYY-MM-DD", nil)
		}
		svcReq.StartDate = t
	}
	if req.PrepaidDueDate != nil {
		t, err := parseDate(*req.PrepaidDueDate)
		if err != nil {
			return utils.ErrorResponse(c, fiber.StatusBadRequest,
				"VALIDATION_ERROR", "prepaid_due_date must be YYYY-MM-DD", nil)
		}
		svcReq.PrepaidDueDate = &t
	}

	sub, err := h.svc.AssignPlan(c.UserContext(), memberID, svcReq)
	if err != nil {
		switch {
		case errors.Is(err, services.ErrNotFound):
			return utils.ErrorResponse(c, fiber.StatusNotFound, "NOT_FOUND", err.Error(), nil)
		case errors.Is(err, services.ErrMemberInactive):
			return utils.ErrorResponse(c, fiber.StatusUnprocessableEntity,
				"MEMBER_INACTIVE", "Cannot assign a plan to an inactive member", nil)
		default:
			h.log.ErrorContext(c.UserContext(), "assign plan", "error", err)
			return utils.ErrorResponse(c, fiber.StatusInternalServerError, "INTERNAL_ERROR", "Could not assign plan", nil)
		}
	}

	return utils.SuccessResponse(c, fiber.StatusCreated, sub)
}

// ListSubscriptions godoc
// @Summary     List all subscriptions for a member
// @Tags        admin/subscriptions
// @Security    BearerAuth
// @Produce     json
// @Param       id path string true "Member UUID"
// @Success     200 {object} map[string]any
// @Router      /api/v1/admin/members/{id}/subscriptions [get]
func (h *AdminSubscriptionHandler) ListSubscriptions(c *fiber.Ctx) error {
	memberID, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return utils.ErrorResponse(c, fiber.StatusBadRequest,
			"INVALID_ID", "Member ID must be a valid UUID", nil)
	}

	subs, err := h.svc.ListSubscriptions(c.UserContext(), memberID)
	if err != nil {
		if errors.Is(err, services.ErrNotFound) {
			return utils.ErrorResponse(c, fiber.StatusNotFound, "NOT_FOUND", "Member not found", nil)
		}
		h.log.ErrorContext(c.UserContext(), "list subscriptions", "error", err)
		return utils.ErrorResponse(c, fiber.StatusInternalServerError, "INTERNAL_ERROR", "Could not fetch subscriptions", nil)
	}

	return utils.SuccessResponse(c, fiber.StatusOK, subs)
}

// UpdateActive godoc
// @Summary     Update the active subscription (price, end_date, note)
// @Tags        admin/subscriptions
// @Security    BearerAuth
// @Accept      json
// @Produce     json
// @Param       id   path string         true "Member UUID"
// @Param       body body updateActiveReq true "Fields to update"
// @Success     200 {object} map[string]any
// @Failure     404,422 {object} map[string]any
// @Router      /api/v1/admin/members/{id}/subscriptions/active [patch]
func (h *AdminSubscriptionHandler) UpdateActive(c *fiber.Ctx) error {
	memberID, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return utils.ErrorResponse(c, fiber.StatusBadRequest,
			"INVALID_ID", "Member ID must be a valid UUID", nil)
	}

	var req updateActiveReq
	if !parseAndValidate(c, &req) {
		return nil
	}

	startDate, err := parseDate(req.StartDate)
	if err != nil {
		return utils.ErrorResponse(c, fiber.StatusBadRequest,
			"VALIDATION_ERROR", "start_date must be YYYY-MM-DD", nil)
	}

	endDate, err := parseDate(req.EndDate)
	if err != nil {
		return utils.ErrorResponse(c, fiber.StatusBadRequest,
			"VALIDATION_ERROR", "end_date must be YYYY-MM-DD", nil)
	}

	svcUpdateReq := services.UpdateActiveRequest{
		StartDate:           startDate,
		EndDate:             endDate,
		FinalPrice:          req.FinalPrice,
		Note:                req.Note,
		BillingType:         req.BillingType,
		PostpaidGraceBefore: req.PostpaidGraceBefore,
		PostpaidGraceAfter:  req.PostpaidGraceAfter,
	}
	if req.PrepaidDueDate != nil {
		t, err := parseDate(*req.PrepaidDueDate)
		if err != nil {
			return utils.ErrorResponse(c, fiber.StatusBadRequest,
				"VALIDATION_ERROR", "prepaid_due_date must be YYYY-MM-DD", nil)
		}
		svcUpdateReq.PrepaidDueDate = &t
	}

	sub, err := h.svc.UpdateActive(c.UserContext(), memberID, svcUpdateReq)
	if err != nil {
		if errors.Is(err, services.ErrNotFound) {
			return utils.ErrorResponse(c, fiber.StatusNotFound, "NOT_FOUND", "No active subscription found", nil)
		}
		h.log.ErrorContext(c.UserContext(), "update active subscription", "error", err)
		return utils.ErrorResponse(c, fiber.StatusInternalServerError, "INTERNAL_ERROR", "Update failed", nil)
	}

	return utils.SuccessResponse(c, fiber.StatusOK, sub)
}
