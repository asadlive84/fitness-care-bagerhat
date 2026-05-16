package handlers

import (
	"context"
	"encoding/json"
	"log/slog"

	"github.com/asadlive84/fitness-care-bagerhat/internal/models"
	"github.com/asadlive84/fitness-care-bagerhat/internal/services"
	"github.com/asadlive84/fitness-care-bagerhat/internal/utils"
	"github.com/gofiber/fiber/v2"
)

type adminSettingSvc interface {
	GetAll(ctx context.Context) ([]*models.Setting, error)
	UpsertSetting(ctx context.Context, key string, value json.RawMessage) (*models.Setting, error)
}

// AdminSettingsHandler holds HTTP handlers for settings management.
type AdminSettingsHandler struct {
	svc adminSettingSvc
	log *slog.Logger
}

// NewAdminSettingsHandler creates an AdminSettingsHandler.
func NewAdminSettingsHandler(svc *services.SettingService, log *slog.Logger) *AdminSettingsHandler {
	return &AdminSettingsHandler{svc: svc, log: log}
}

// NewAdminSettingsHandlerWithSvc injects any adminSettingSvc — used in tests.
func NewAdminSettingsHandlerWithSvc(svc adminSettingSvc, log *slog.Logger) *AdminSettingsHandler {
	return &AdminSettingsHandler{svc: svc, log: log}
}

// ── DTOs ──────────────────────────────────────────────────────────────────────

type upsertSettingReq struct {
	Key   string          `json:"key"   validate:"required,min=1,max=100"`
	Value json.RawMessage `json:"value" validate:"required"`
}

// ── Handlers ──────────────────────────────────────────────────────────────────

// GetSettings godoc
// @Summary     Get all settings
// @Tags        admin/settings
// @Security    BearerAuth
// @Produce     json
// @Success     200 {object} map[string]any
// @Router      /api/v1/admin/settings [get]
func (h *AdminSettingsHandler) GetSettings(c *fiber.Ctx) error {
	settings, err := h.svc.GetAll(c.UserContext())
	if err != nil {
		h.log.ErrorContext(c.UserContext(), "get settings", "error", err)
		return utils.ErrorResponse(c, fiber.StatusInternalServerError, "INTERNAL_ERROR", "Could not fetch settings", nil)
	}
	return utils.SuccessResponse(c, fiber.StatusOK, settings)
}

// UpdateSetting godoc
// @Summary     Create or update a setting
// @Tags        admin/settings
// @Security    BearerAuth
// @Accept      json
// @Produce     json
// @Param       body body upsertSettingReq true "Setting key + value"
// @Success     200 {object} map[string]any
// @Router      /api/v1/admin/settings [patch]
func (h *AdminSettingsHandler) UpdateSetting(c *fiber.Ctx) error {
	var req upsertSettingReq
	if !parseAndValidate(c, &req) {
		return nil
	}

	// Validate that value is parseable JSON (validator only checks non-empty).
	if !json.Valid(req.Value) {
		return utils.ErrorResponse(c, fiber.StatusBadRequest,
			"VALIDATION_ERROR", "value must be valid JSON", nil)
	}

	setting, err := h.svc.UpsertSetting(c.UserContext(), req.Key, req.Value)
	if err != nil {
		h.log.ErrorContext(c.UserContext(), "upsert setting", "error", err)
		return utils.ErrorResponse(c, fiber.StatusInternalServerError, "INTERNAL_ERROR", "Could not save setting", nil)
	}
	return utils.SuccessResponse(c, fiber.StatusOK, setting)
}
