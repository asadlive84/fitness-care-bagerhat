package handlers

import (
	"context"
	"log/slog"
	"strconv"
	"time"

	"github.com/asadlive84/fitness-care-bagerhat/internal/models"
	"github.com/asadlive84/fitness-care-bagerhat/internal/services"
	"github.com/asadlive84/fitness-care-bagerhat/internal/utils"
	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
)

type expenseSvc interface {
	RecordExpense(ctx context.Context, req services.RecordExpenseRequest) (*models.Expense, error)
	ListExpenses(ctx context.Context, filter models.ListExpensesFilter) ([]*models.Expense, int64, error)
	GetExpensesSummary(ctx context.Context) (*models.ExpensesSummary, error)
	GetDailyFinancials(ctx context.Context, month time.Time) ([]*models.DailyFinancial, error)
}

// AdminExpenseHandler holds HTTP handlers for operational expenses and financials.
type AdminExpenseHandler struct {
	svc expenseSvc
	log *slog.Logger
}

// NewAdminExpenseHandler creates an AdminExpenseHandler.
func NewAdminExpenseHandler(svc *services.ExpenseService, log *slog.Logger) *AdminExpenseHandler {
	return &AdminExpenseHandler{svc: svc, log: log}
}

// NewAdminExpenseHandlerWithSvc injects any expenseSvc — used in tests.
func NewAdminExpenseHandlerWithSvc(svc expenseSvc, log *slog.Logger) *AdminExpenseHandler {
	return &AdminExpenseHandler{svc: svc, log: log}
}

// ── DTOs ──────────────────────────────────────────────────────────────────────

type recordExpenseReq struct {
	Amount      float64 `json:"amount"      validate:"required,gt=0"`
	Description string  `json:"description" validate:"required"`
	Category    string  `json:"category"    validate:"required,oneof=Water Bill Salary Rent Maintenance Others"`
	SpentAt     *string `json:"spent_at"` // optional RFC3339 timestamp
}

// ── Handlers ──────────────────────────────────────────────────────────────────

// RecordExpense godoc
// @Summary     Log an operational expense
// @Tags        admin/expenses
// @Security    BearerAuth
// @Accept      json
// @Produce     json
// @Param       body body recordExpenseReq true "Expense details"
// @Success     201 {object} map[string]any
// @Router      /api/v1/admin/expenses [post]
func (h *AdminExpenseHandler) RecordExpense(c *fiber.Ctx) error {
	var req recordExpenseReq
	if !parseAndValidate(c, &req) {
		return nil
	}

	adminIDStr, _ := c.Locals("user_id").(string)
	adminID, err := uuid.Parse(adminIDStr)
	if err != nil {
		return utils.ErrorResponse(c, fiber.StatusUnauthorized,
			"UNAUTHORIZED", "Invalid admin token", nil)
	}

	svcReq := services.RecordExpenseRequest{
		Amount:      req.Amount,
		Description: req.Description,
		Category:    req.Category,
		RecordedBy:  adminID,
	}

	if req.SpentAt != nil && *req.SpentAt != "" {
		t, err := time.Parse(time.RFC3339, *req.SpentAt)
		if err != nil {
			return utils.ErrorResponse(c, fiber.StatusBadRequest,
				"VALIDATION_ERROR", "spent_at must be RFC3339 (e.g. 2026-05-23T07:26:00Z)", nil)
		}
		svcReq.SpentAt = t
	}

	expense, err := h.svc.RecordExpense(c.UserContext(), svcReq)
	if err != nil {
		h.log.ErrorContext(c.UserContext(), "record expense failed", "error", err)
		return utils.ErrorResponse(c, fiber.StatusInternalServerError, "INTERNAL_ERROR", "Could not record expense", nil)
	}

	return c.Status(fiber.StatusCreated).JSON(fiber.Map{
		"success": true,
		"data":    expense,
	})
}

// ListExpenses godoc
// @Summary     List operational expenses
// @Tags        admin/expenses
// @Security    BearerAuth
// @Produce     json
// @Param       page  query int false "Page number"
// @Param       limit query int false "Items per page"
// @Param       from  query string false "Filter start date (RFC3339)"
// @Param       to    query string false "Filter end date (RFC3339)"
// @Success     200 {object} map[string]any
// @Router      /api/v1/admin/expenses [get]
func (h *AdminExpenseHandler) ListExpenses(c *fiber.Ctx) error {
	page, _ := strconv.Atoi(c.Query("page", "1"))
	limit, _ := strconv.Atoi(c.Query("limit", "20"))
	fromStr := c.Query("from")
	toStr := c.Query("to")

	filter := models.ListExpensesFilter{
		Page:  page,
		Limit: limit,
	}

	if fromStr != "" {
		if t, err := time.Parse(time.RFC3339, fromStr); err == nil {
			filter.From = &t
		} else {
			return utils.ErrorResponse(c, fiber.StatusBadRequest,
				"VALIDATION_ERROR", "from date must be RFC3339", nil)
		}
	}

	if toStr != "" {
		if t, err := time.Parse(time.RFC3339, toStr); err == nil {
			filter.To = &t
		} else {
			return utils.ErrorResponse(c, fiber.StatusBadRequest,
				"VALIDATION_ERROR", "to date must be RFC3339", nil)
		}
	}

	expenses, total, err := h.svc.ListExpenses(c.UserContext(), filter)
	if err != nil {
		h.log.ErrorContext(c.UserContext(), "list expenses failed", "error", err)
		return utils.ErrorResponse(c, fiber.StatusInternalServerError, "INTERNAL_ERROR", "Could not list expenses", nil)
	}

	hasMore := int64(page*limit) < total

	return c.Status(fiber.StatusOK).JSON(fiber.Map{
		"success": true,
		"data":    expenses,
		"meta": fiber.Map{
			"total":    total,
			"page":     page,
			"limit":    limit,
			"has_more": hasMore,
		},
	})
}

// GetExpensesSummary godoc
// @Summary     Get operational expense summaries (Today, Yesterday, This Month)
// @Tags        admin/expenses
// @Security    BearerAuth
// @Produce     json
// @Success     200 {object} map[string]any
// @Router      /api/v1/admin/expenses/summary [get]
func (h *AdminExpenseHandler) GetExpensesSummary(c *fiber.Ctx) error {
	summary, err := h.svc.GetExpensesSummary(c.UserContext())
	if err != nil {
		h.log.ErrorContext(c.UserContext(), "get expenses summary failed", "error", err)
		return utils.ErrorResponse(c, fiber.StatusInternalServerError, "INTERNAL_ERROR", "Could not get expenses summary", nil)
	}

	return c.Status(fiber.StatusOK).JSON(fiber.Map{
		"success": true,
		"data":    summary,
	})
}

// GetDailyFinancials godoc
// @Summary     Get combined daily financials calendar ledger for a month
// @Tags        admin/expenses
// @Security    BearerAuth
// @Produce     json
// @Param       month query string true "Month (format: YYYY-MM)"
// @Success     200 {object} map[string]any
// @Router      /api/v1/admin/financials/calendar [get]
func (h *AdminExpenseHandler) GetDailyFinancials(c *fiber.Ctx) error {
	monthStr := c.Query("month")
	if monthStr == "" {
		return utils.ErrorResponse(c, fiber.StatusBadRequest,
			"VALIDATION_ERROR", "month query parameter is required (format: YYYY-MM)", nil)
	}

	month, err := time.Parse("2006-01", monthStr)
	if err != nil {
		return utils.ErrorResponse(c, fiber.StatusBadRequest,
			"VALIDATION_ERROR", "month must be in YYYY-MM format (e.g. 2026-05)", nil)
	}

	financials, err := h.svc.GetDailyFinancials(c.UserContext(), month)
	if err != nil {
		h.log.ErrorContext(c.UserContext(), "get daily financials failed", "error", err)
		return utils.ErrorResponse(c, fiber.StatusInternalServerError, "INTERNAL_ERROR", "Could not get daily financials", nil)
	}

	// Format daily financials for JSON serialization to avoid time.Time serialization issues with timezone
	formatted := make([]fiber.Map, len(financials))
	for i, f := range financials {
		formatted[i] = fiber.Map{
			"date":     f.Date.Format("2006-01-02"),
			"earnings": f.Earnings,
			"expenses": f.Expenses,
			"net":      f.Net,
		}
	}

	return c.Status(fiber.StatusOK).JSON(fiber.Map{
		"success": true,
		"data":    formatted,
	})
}
