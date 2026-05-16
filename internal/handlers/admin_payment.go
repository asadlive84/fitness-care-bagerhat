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

type adminPaymentSvc interface {
	RecordPayment(ctx context.Context, req services.RecordPaymentRequest) (*models.Payment, error)
	ListMemberPayments(ctx context.Context, memberID uuid.UUID, filter models.PaymentFilter) ([]*models.Payment, error)
	GetMonthlySummary(ctx context.Context, month time.Time) (*models.PaymentSummary, error)
}

// AdminPaymentHandler holds HTTP handlers for payment management.
type AdminPaymentHandler struct {
	svc adminPaymentSvc
	log *slog.Logger
}

// NewAdminPaymentHandler creates an AdminPaymentHandler.
func NewAdminPaymentHandler(svc *services.PaymentService, log *slog.Logger) *AdminPaymentHandler {
	return &AdminPaymentHandler{svc: svc, log: log}
}

// NewAdminPaymentHandlerWithSvc injects any adminPaymentSvc — used in tests.
func NewAdminPaymentHandlerWithSvc(svc adminPaymentSvc, log *slog.Logger) *AdminPaymentHandler {
	return &AdminPaymentHandler{svc: svc, log: log}
}

// ── DTOs ──────────────────────────────────────────────────────────────────────

type recordPaymentReq struct {
	MemberID       string   `json:"member_id"       validate:"required,uuid"`
	SubscriptionID string   `json:"subscription_id" validate:"required,uuid"`
	Amount         float64  `json:"amount"          validate:"required,gt=0"`
	Method         string   `json:"method"          validate:"required,oneof=Cash bKash Nagad Card"`
	PaidAt         *string  `json:"paid_at"` // optional RFC3339 timestamp
}

// ── Handlers ──────────────────────────────────────────────────────────────────

// RecordPayment godoc
// @Summary     Record a payment
// @Tags        admin/payments
// @Security    BearerAuth
// @Accept      json
// @Produce     json
// @Param       body body recordPaymentReq true "Payment details"
// @Success     201 {object} map[string]any
// @Router      /api/v1/admin/payments [post]
func (h *AdminPaymentHandler) RecordPayment(c *fiber.Ctx) error {
	var req recordPaymentReq
	if !parseAndValidate(c, &req) {
		return nil
	}

	memberID, _ := uuid.Parse(req.MemberID)
	subID, _ := uuid.Parse(req.SubscriptionID)

	adminIDStr, _ := c.Locals("user_id").(string)
	adminID, err := uuid.Parse(adminIDStr)
	if err != nil {
		return utils.ErrorResponse(c, fiber.StatusUnauthorized,
			"UNAUTHORIZED", "Invalid admin token", nil)
	}

	svcReq := services.RecordPaymentRequest{
		MemberID:       memberID,
		SubscriptionID: subID,
		Amount:         req.Amount,
		Method:         req.Method,
		AdminID:        adminID,
	}

	if req.PaidAt != nil {
		t, err := time.Parse(time.RFC3339, *req.PaidAt)
		if err != nil {
			return utils.ErrorResponse(c, fiber.StatusBadRequest,
				"VALIDATION_ERROR", "paid_at must be RFC3339 (e.g. 2026-05-16T10:00:00Z)", nil)
		}
		svcReq.PaidAt = t
	}

	payment, err := h.svc.RecordPayment(c.UserContext(), svcReq)
	if err != nil {
		if errors.Is(err, services.ErrNotFound) {
			return utils.ErrorResponse(c, fiber.StatusNotFound, "NOT_FOUND", err.Error(), nil)
		}
		h.log.ErrorContext(c.UserContext(), "record payment", "error", err)
		return utils.ErrorResponse(c, fiber.StatusInternalServerError, "INTERNAL_ERROR", "Could not record payment", nil)
	}

	return utils.SuccessResponse(c, fiber.StatusCreated, payment)
}

// ListMemberPayments godoc
// @Summary     List payments for a member (with optional date range)
// @Tags        admin/payments
// @Security    BearerAuth
// @Produce     json
// @Param       id   path  string false "Member UUID"
// @Param       from query string false "From date (YYYY-MM-DD)"
// @Param       to   query string false "To date (YYYY-MM-DD)"
// @Success     200 {object} map[string]any
// @Router      /api/v1/admin/members/{id}/payments [get]
func (h *AdminPaymentHandler) ListMemberPayments(c *fiber.Ctx) error {
	memberID, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return utils.ErrorResponse(c, fiber.StatusBadRequest,
			"INVALID_ID", "Member ID must be a valid UUID", nil)
	}

	filter, err := parseDateRangeFilter(c)
	if err != nil {
		return utils.ErrorResponse(c, fiber.StatusBadRequest,
			"VALIDATION_ERROR", err.Error(), nil)
	}

	payments, err := h.svc.ListMemberPayments(c.UserContext(), memberID, filter)
	if err != nil {
		if errors.Is(err, services.ErrNotFound) {
			return utils.ErrorResponse(c, fiber.StatusNotFound, "NOT_FOUND", "Member not found", nil)
		}
		h.log.ErrorContext(c.UserContext(), "list member payments", "error", err)
		return utils.ErrorResponse(c, fiber.StatusInternalServerError, "INTERNAL_ERROR", "Could not fetch payments", nil)
	}

	return utils.SuccessResponse(c, fiber.StatusOK, payments)
}

// GetPaymentSummary godoc
// @Summary     Monthly payment summary (total revenue)
// @Tags        admin/payments
// @Security    BearerAuth
// @Produce     json
// @Param       month query string true "Month (YYYY-MM)"
// @Success     200 {object} map[string]any
// @Router      /api/v1/admin/payments/summary [get]
func (h *AdminPaymentHandler) GetPaymentSummary(c *fiber.Ctx) error {
	monthStr := c.Query("month")
	if monthStr == "" {
		return utils.ErrorResponse(c, fiber.StatusBadRequest,
			"VALIDATION_ERROR", "month query param is required (YYYY-MM)", nil)
	}

	month, err := time.Parse("2006-01", monthStr)
	if err != nil {
		return utils.ErrorResponse(c, fiber.StatusBadRequest,
			"VALIDATION_ERROR", "month must be in YYYY-MM format", nil)
	}

	summary, err := h.svc.GetMonthlySummary(c.UserContext(), month)
	if err != nil {
		h.log.ErrorContext(c.UserContext(), "get payment summary", "error", err)
		return utils.ErrorResponse(c, fiber.StatusInternalServerError, "INTERNAL_ERROR", "Could not fetch summary", nil)
	}

	return utils.SuccessResponse(c, fiber.StatusOK, summary)
}

// ── helpers ───────────────────────────────────────────────────────────────────

// parseDateRangeFilter parses optional ?from=YYYY-MM-DD&to=YYYY-MM-DD query params.
func parseDateRangeFilter(c *fiber.Ctx) (models.PaymentFilter, error) {
	var filter models.PaymentFilter

	if fromStr := c.Query("from"); fromStr != "" {
		t, err := time.Parse("2006-01-02", fromStr)
		if err != nil {
			return filter, fmt.Errorf("from must be YYYY-MM-DD")
		}
		filter.From = &t
	}

	if toStr := c.Query("to"); toStr != "" {
		t, err := time.Parse("2006-01-02", toStr)
		if err != nil {
			return filter, fmt.Errorf("to must be YYYY-MM-DD")
		}
		// Include the full "to" day by advancing to end of day.
		t = t.Add(24*time.Hour - time.Second)
		filter.To = &t
	}

	return filter, nil
}
