package handlers

import (
	"context"
	"encoding/json"
	"fmt"
	"log/slog"
	"time"

	"github.com/asadlive84/fitness-care-bagerhat/internal/repositories"
	"github.com/asadlive84/fitness-care-bagerhat/internal/utils"
	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
)

type memberFCMRepo interface {
	Upsert(ctx context.Context, memberID uuid.UUID, token string, deviceInfo *string) error
}

type memberSettingRepo interface {
	Upsert(ctx context.Context, key string, value json.RawMessage) error
}

// MemberNotificationHandler holds endpoints for member notification preferences.
type MemberNotificationHandler struct {
	fcmTokens memberFCMRepo
	settings  memberSettingRepo
	log       *slog.Logger
}

// NewMemberNotificationHandler creates a MemberNotificationHandler.
func NewMemberNotificationHandler(
	fcmTokens repositories.FCMTokenRepository,
	settings repositories.SettingRepository,
	log *slog.Logger,
) *MemberNotificationHandler {
	return &MemberNotificationHandler{
		fcmTokens: fcmTokens,
		settings:  &settingAdapter{settings},
		log:       log,
	}
}

// ── DTOs ──────────────────────────────────────────────────────────────────────

type registerFCMTokenReq struct {
	Token      string  `json:"token"       validate:"required,min=10"`
	DeviceInfo *string `json:"device_info"`
}

type muteNotificationsReq struct {
	Muted bool    `json:"muted"`
	Until *string `json:"until"` // optional RFC3339 timestamp
}

// mutePayload is stored in the settings table.
type mutePayload struct {
	Muted bool       `json:"muted"`
	Until *time.Time `json:"until,omitempty"`
}

// ── Handlers ──────────────────────────────────────────────────────────────────

// RegisterFCMToken godoc
// @Summary     Register or refresh a device FCM token
// @Tags        member/notifications
// @Security    BearerAuth
// @Accept      json
// @Produce     json
// @Param       body body registerFCMTokenReq true "Token details"
// @Success     204
// @Router      /api/v1/member/fcm-token [post]
func (h *MemberNotificationHandler) RegisterFCMToken(c *fiber.Ctx) error {
	id, err := memberID(c)
	if err != nil {
		return utils.ErrorResponse(c, fiber.StatusUnauthorized, "UNAUTHORIZED", "Invalid token", nil)
	}

	var req registerFCMTokenReq
	if !parseAndValidate(c, &req) {
		return nil
	}

	if err := h.fcmTokens.Upsert(c.UserContext(), id, req.Token, req.DeviceInfo); err != nil {
		h.log.ErrorContext(c.UserContext(), "register fcm token", "error", err)
		return utils.ErrorResponse(c, fiber.StatusInternalServerError, "INTERNAL_ERROR", "Could not register token", nil)
	}
	return c.SendStatus(fiber.StatusNoContent)
}

// MuteNotifications godoc
// @Summary     Mute or unmute push notifications
// @Tags        member/notifications
// @Security    BearerAuth
// @Accept      json
// @Produce     json
// @Param       body body muteNotificationsReq true "Mute preference"
// @Success     204
// @Router      /api/v1/member/notifications/mute [patch]
func (h *MemberNotificationHandler) MuteNotifications(c *fiber.Ctx) error {
	id, err := memberID(c)
	if err != nil {
		return utils.ErrorResponse(c, fiber.StatusUnauthorized, "UNAUTHORIZED", "Invalid token", nil)
	}

	var req muteNotificationsReq
	if !parseAndValidate(c, &req) {
		return nil
	}

	payload := mutePayload{Muted: req.Muted}
	if req.Until != nil {
		t, err := time.Parse(time.RFC3339, *req.Until)
		if err != nil {
			return utils.ErrorResponse(c, fiber.StatusBadRequest,
				"VALIDATION_ERROR", "until must be RFC3339 timestamp", nil)
		}
		payload.Until = &t
	}

	raw, _ := json.Marshal(payload)
	key := fmt.Sprintf("member_mute:%s", id)
	if err := h.settings.Upsert(c.UserContext(), key, raw); err != nil {
		h.log.ErrorContext(c.UserContext(), "mute notifications", "error", err)
		return utils.ErrorResponse(c, fiber.StatusInternalServerError, "INTERNAL_ERROR", "Could not save preference", nil)
	}
	return c.SendStatus(fiber.StatusNoContent)
}

// ── adapters ──────────────────────────────────────────────────────────────────

// settingAdapter adapts SettingRepository to the minimal interface needed here.
type settingAdapter struct {
	repo repositories.SettingRepository
}

func (a *settingAdapter) Upsert(ctx context.Context, key string, value json.RawMessage) error {
	_, err := a.repo.Upsert(ctx, key, value, nil)
	return err
}
