package handlers

import (
	"database/sql"
	"log/slog"
	"strconv"
	"time"

	sqlcdb "github.com/asadlive84/fitness-care-bagerhat/internal/database/sqlc"
	"github.com/asadlive84/fitness-care-bagerhat/internal/repositories/postgres"
	"github.com/asadlive84/fitness-care-bagerhat/internal/utils"
	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
)

// SuperAdminAuditHandler exposes the global AI audit + cost endpoints.
type SuperAdminAuditHandler struct {
	ai  *postgres.AIRepo
	log *slog.Logger
}

func NewSuperAdminAuditHandler(ai *postgres.AIRepo, log *slog.Logger) *SuperAdminAuditHandler {
	return &SuperAdminAuditHandler{ai: ai, log: log.With(slog.String("component", "superadmin_audit"))}
}

// ── helpers ──────────────────────────────────────────────────────────────────

func parseNullUUID(s string) uuid.NullUUID {
	if s == "" {
		return uuid.NullUUID{}
	}
	u, err := uuid.Parse(s)
	if err != nil {
		return uuid.NullUUID{}
	}
	return uuid.NullUUID{UUID: u, Valid: true}
}

func parseNullText(s string) sql.NullString {
	if s == "" {
		return sql.NullString{}
	}
	return sql.NullString{String: s, Valid: true}
}

func parseNullTime(s string) sql.NullTime {
	if s == "" {
		return sql.NullTime{}
	}
	t, err := time.Parse(time.RFC3339, s)
	if err != nil {
		// try date-only
		t, err = time.Parse("2006-01-02", s)
		if err != nil {
			return sql.NullTime{}
		}
	}
	return sql.NullTime{Time: t, Valid: true}
}

// ── Handlers ─────────────────────────────────────────────────────────────────

// ListAIAudit godoc
// @Summary     List AI audit log entries (paginated, filterable)
// @Tags        superadmin/audit
// @Security    BearerAuth
// @Produce     json
// @Param       admin_id    query string false "Filter by gym admin UUID"
// @Param       member_id   query string false "Filter by member UUID"
// @Param       prompt_type query string false "diet_chart | food_log | chat"
// @Param       from        query string false "RFC3339 or YYYY-MM-DD"
// @Param       to          query string false "RFC3339 or YYYY-MM-DD"
// @Param       page        query int    false "Page (default 1)"
// @Param       limit       query int    false "Limit (default 20, max 100)"
// @Success     200 {object} map[string]any
// @Router      /api/v1/superadmin/audit/ai [get]
func (h *SuperAdminAuditHandler) ListAIAudit(c *fiber.Ctx) error {
	ctx := c.UserContext()

	page, _ := strconv.Atoi(c.Query("page", "1"))
	if page < 1 {
		page = 1
	}
	limit, _ := strconv.Atoi(c.Query("limit", "20"))
	if limit < 1 || limit > 100 {
		limit = 20
	}

	params := sqlcdb.ListAIAuditLogsParams{
		AdminID:     parseNullUUID(c.Query("admin_id")),
		MemberID:    parseNullUUID(c.Query("member_id")),
		PromptType:  parseNullText(c.Query("prompt_type")),
		FromTime:    parseNullTime(c.Query("from")),
		ToTime:      parseNullTime(c.Query("to")),
		LimitCount:  int32(limit),
		OffsetCount: int32((page - 1) * limit),
	}

	logs, err := h.ai.ListAIAuditLogs(ctx, params)
	if err != nil {
		h.log.ErrorContext(ctx, "list ai audit", "error", err)
		return utils.ErrorResponse(c, fiber.StatusInternalServerError, "INTERNAL_ERROR", "Could not fetch audit logs", nil)
	}

	total, _ := h.ai.CountAIAuditLogs(ctx, sqlcdb.CountAIAuditLogsParams{
		AdminID: params.AdminID, MemberID: params.MemberID, PromptType: params.PromptType,
		FromTime: params.FromTime, ToTime: params.ToTime,
	})

	// Reshape to a flatter JSON payload
	items := make([]fiber.Map, 0, len(logs))
	for _, l := range logs {
		items = append(items, fiber.Map{
			"id":                l.ID,
			"member_id":         l.MemberID,
			"admin_id":          l.AdminID,
			"prompt_type":       l.PromptType,
			"prompt_text":       l.PromptText,
			"ai_response_json":  l.AiResponseJson,
			"prompt_tokens":     l.PromptTokens,
			"completion_tokens": l.CompletionTokens,
			"total_tokens":      l.TotalTokens,
			"estimated_cost":    l.EstimatedCost,
			"created_at":        l.CreatedAt,
		})
	}

	return c.Status(fiber.StatusOK).JSON(fiber.Map{
		"success": true,
		"data":    items,
		"meta":    fiber.Map{"page": page, "limit": limit, "total": total},
	})
}

// AICostByGym godoc
// @Summary     Aggregate AI cost & tokens per gym
// @Tags        superadmin/audit
// @Security    BearerAuth
// @Produce     json
// @Param       from query string false "RFC3339 or YYYY-MM-DD"
// @Param       to   query string false "RFC3339 or YYYY-MM-DD"
// @Success     200 {object} map[string]any
// @Router      /api/v1/superadmin/audit/ai/cost-by-gym [get]
func (h *SuperAdminAuditHandler) AICostByGym(c *fiber.Ctx) error {
	ctx := c.UserContext()
	rows, err := h.ai.AICostByGym(ctx, sqlcdb.AICostByGymParams{
		FromTime: parseNullTime(c.Query("from")),
		ToTime:   parseNullTime(c.Query("to")),
	})
	if err != nil {
		h.log.ErrorContext(ctx, "cost by gym", "error", err)
		return utils.ErrorResponse(c, fiber.StatusInternalServerError, "INTERNAL_ERROR", "Aggregation failed", nil)
	}
	return utils.SuccessResponse(c, fiber.StatusOK, rows)
}

// AIHeavyUsers godoc
// @Summary     Members with highest AI consumption above a token threshold
// @Tags        superadmin/audit
// @Security    BearerAuth
// @Produce     json
// @Param       from      query string false "RFC3339 or YYYY-MM-DD"
// @Param       to        query string false "RFC3339 or YYYY-MM-DD"
// @Param       threshold query int    false "Min total tokens (default 0)"
// @Param       limit     query int    false "Max rows (default 25)"
// @Success     200 {object} map[string]any
// @Router      /api/v1/superadmin/audit/ai/heavy-users [get]
func (h *SuperAdminAuditHandler) AIHeavyUsers(c *fiber.Ctx) error {
	ctx := c.UserContext()
	threshold, _ := strconv.ParseInt(c.Query("threshold", "0"), 10, 64)
	limit, _ := strconv.Atoi(c.Query("limit", "25"))
	if limit < 1 || limit > 100 {
		limit = 25
	}

	rows, err := h.ai.AIHeavyUsers(ctx, sqlcdb.AIHeavyUsersParams{
		FromTime:   parseNullTime(c.Query("from")),
		ToTime:     parseNullTime(c.Query("to")),
		Threshold:  threshold,
		LimitCount: int32(limit),
	})
	if err != nil {
		h.log.ErrorContext(ctx, "heavy users", "error", err)
		return utils.ErrorResponse(c, fiber.StatusInternalServerError, "INTERNAL_ERROR", "Aggregation failed", nil)
	}
	return utils.SuccessResponse(c, fiber.StatusOK, rows)
}
