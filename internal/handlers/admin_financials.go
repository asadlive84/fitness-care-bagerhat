package handlers

import (
	"context"
	"log/slog"
	"time"

	"github.com/asadlive84/fitness-care-bagerhat/internal/models"
	"github.com/asadlive84/fitness-care-bagerhat/internal/services"
	"github.com/asadlive84/fitness-care-bagerhat/internal/utils"
	"github.com/gofiber/fiber/v2"
)

type financialsSvc interface {
	GetFinancialsReport(ctx context.Context, start, end time.Time) (*models.FinancialsReport, error)
}

// AdminFinancialsHandler holds HTTP handlers for centralized reporting.
type AdminFinancialsHandler struct {
	svc financialsSvc
	log *slog.Logger
}

// NewAdminFinancialsHandler creates an AdminFinancialsHandler.
func NewAdminFinancialsHandler(svc *services.FinancialsService, log *slog.Logger) *AdminFinancialsHandler {
	return &AdminFinancialsHandler{svc: svc, log: log}
}

// GetFinancialsReport godoc
// @Summary     Get centralized financial analytics report
// @Tags        admin/financials
// @Security    BearerAuth
// @Produce     json
// @Param       from query string true "Report start date (RFC3339)"
// @Param       to   query string true "Report end date (RFC3339)"
// @Success     200 {object} map[string]any
// @Router      /api/v1/admin/financials/report [get]
func (h *AdminFinancialsHandler) GetFinancialsReport(c *fiber.Ctx) error {
	fromStr := c.Query("from")
	toStr := c.Query("to")

	if fromStr == "" || toStr == "" {
		return utils.ErrorResponse(c, fiber.StatusBadRequest,
			"VALIDATION_ERROR", "both 'from' and 'to' query parameters are required", nil)
	}

	start, err := time.Parse(time.RFC3339, fromStr)
	if err != nil {
		return utils.ErrorResponse(c, fiber.StatusBadRequest,
			"VALIDATION_ERROR", "invalid 'from' timestamp: must be RFC3339 (e.g. 2026-05-23T00:00:00Z)", nil)
	}

	end, err := time.Parse(time.RFC3339, toStr)
	if err != nil {
		return utils.ErrorResponse(c, fiber.StatusBadRequest,
			"VALIDATION_ERROR", "invalid 'to' timestamp: must be RFC3339 (e.g. 2026-05-23T23:59:59Z)", nil)
	}

	if start.After(end) {
		return utils.ErrorResponse(c, fiber.StatusBadRequest,
			"VALIDATION_ERROR", "'from' date cannot be after 'to' date", nil)
	}

	report, err := h.svc.GetFinancialsReport(c.UserContext(), start, end)
	if err != nil {
		h.log.ErrorContext(c.UserContext(), "generate financials report failed", "error", err)
		return utils.ErrorResponse(c, fiber.StatusInternalServerError, "INTERNAL_ERROR", "Could not generate report", nil)
	}

	// Format daily timeline dates to simple strings for clean JSON serialization
	timelineFormatted := make([]fiber.Map, len(report.Timeline))
	for i, f := range report.Timeline {
		timelineFormatted[i] = fiber.Map{
			"date":     f.Date.Format("2006-01-02"),
			"earnings": f.Earnings,
			"expenses": f.Expenses,
			"net":      f.Net,
		}
	}

	return c.Status(fiber.StatusOK).JSON(fiber.Map{
		"success": true,
		"data": fiber.Map{
			"start_date":            report.StartDate.Format(time.RFC3339),
			"end_date":              report.EndDate.Format(time.RFC3339),
			"total_income":          report.TotalIncome,
			"total_cost":            report.TotalCost,
			"net_profit":            report.NetProfit,
			"timeline":              timelineFormatted,
			"revenue_by_plan":       report.RevenueByPlan,
			"revenue_by_method":     report.RevenueByMethod,
			"expenses_by_category":  report.ExpensesByCategory,
		},
	})
}
