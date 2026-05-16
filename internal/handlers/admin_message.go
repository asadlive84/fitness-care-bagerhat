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

type adminMsgSvc interface {
	SendBroadcast(ctx context.Context, adminID uuid.UUID, content, broadcastFilter string) (*models.Message, error)
	SendDirect(ctx context.Context, adminID, memberID uuid.UUID, content string) (*models.Message, error)
	GetConversations(ctx context.Context) ([]*models.ConversationSummary, error)
	GetConversation(ctx context.Context, memberID uuid.UUID) ([]*models.Message, error)
}

// AdminMessageHandler holds HTTP handlers for admin messaging.
type AdminMessageHandler struct {
	svc adminMsgSvc
	log *slog.Logger
}

// NewAdminMessageHandler creates an AdminMessageHandler.
func NewAdminMessageHandler(svc *services.MessageService, log *slog.Logger) *AdminMessageHandler {
	return &AdminMessageHandler{svc: svc, log: log}
}

// NewAdminMessageHandlerWithSvc injects any adminMsgSvc — used in tests.
func NewAdminMessageHandlerWithSvc(svc adminMsgSvc, log *slog.Logger) *AdminMessageHandler {
	return &AdminMessageHandler{svc: svc, log: log}
}

// ── DTOs ──────────────────────────────────────────────────────────────────────

type broadcastReq struct {
	Content         string `json:"content"          validate:"required,min=1,max=2000"`
	BroadcastFilter string `json:"broadcast_filter" validate:"required,oneof=all active expired expiring"`
}

type directMsgReq struct {
	MemberID string `json:"member_id" validate:"required,uuid"`
	Content  string `json:"content"   validate:"required,min=1,max=2000"`
}

// ── Handlers ──────────────────────────────────────────────────────────────────

// SendBroadcast godoc
// @Summary     Send broadcast message to filtered members
// @Tags        admin/messages
// @Security    BearerAuth
// @Accept      json
// @Produce     json
// @Param       body body broadcastReq true "Broadcast details"
// @Success     201 {object} map[string]any
// @Router      /api/v1/admin/messages/broadcast [post]
func (h *AdminMessageHandler) SendBroadcast(c *fiber.Ctx) error {
	var req broadcastReq
	if !parseAndValidate(c, &req) {
		return nil
	}

	adminID, err := adminIDFromCtx(c)
	if err != nil {
		return utils.ErrorResponse(c, fiber.StatusUnauthorized, "UNAUTHORIZED", "Invalid token", nil)
	}

	msg, err := h.svc.SendBroadcast(c.UserContext(), adminID, req.Content, req.BroadcastFilter)
	if err != nil {
		h.log.ErrorContext(c.UserContext(), "send broadcast", "error", err)
		return utils.ErrorResponse(c, fiber.StatusInternalServerError, "INTERNAL_ERROR", "Could not send broadcast", nil)
	}

	return utils.SuccessResponse(c, fiber.StatusCreated, msg)
}

// SendDirect godoc
// @Summary     Send direct message to a member
// @Tags        admin/messages
// @Security    BearerAuth
// @Accept      json
// @Produce     json
// @Param       body body directMsgReq true "Message details"
// @Success     201 {object} map[string]any
// @Router      /api/v1/admin/messages/direct [post]
func (h *AdminMessageHandler) SendDirect(c *fiber.Ctx) error {
	var req directMsgReq
	if !parseAndValidate(c, &req) {
		return nil
	}

	adminID, err := adminIDFromCtx(c)
	if err != nil {
		return utils.ErrorResponse(c, fiber.StatusUnauthorized, "UNAUTHORIZED", "Invalid token", nil)
	}

	memberID, _ := uuid.Parse(req.MemberID)

	msg, err := h.svc.SendDirect(c.UserContext(), adminID, memberID, req.Content)
	if err != nil {
		if errors.Is(err, services.ErrNotFound) {
			return utils.ErrorResponse(c, fiber.StatusNotFound, "NOT_FOUND", "Member not found", nil)
		}
		h.log.ErrorContext(c.UserContext(), "send direct message", "error", err)
		return utils.ErrorResponse(c, fiber.StatusInternalServerError, "INTERNAL_ERROR", "Could not send message", nil)
	}

	return utils.SuccessResponse(c, fiber.StatusCreated, msg)
}

// ListConversations godoc
// @Summary     List all member conversations (most recent first)
// @Tags        admin/messages
// @Security    BearerAuth
// @Produce     json
// @Success     200 {object} map[string]any
// @Router      /api/v1/admin/messages/conversations [get]
func (h *AdminMessageHandler) ListConversations(c *fiber.Ctx) error {
	conversations, err := h.svc.GetConversations(c.UserContext())
	if err != nil {
		h.log.ErrorContext(c.UserContext(), "list conversations", "error", err)
		return utils.ErrorResponse(c, fiber.StatusInternalServerError, "INTERNAL_ERROR", "Could not fetch conversations", nil)
	}
	return utils.SuccessResponse(c, fiber.StatusOK, conversations)
}

// GetConversation godoc
// @Summary     Get full conversation with a member (marks their messages read)
// @Tags        admin/messages
// @Security    BearerAuth
// @Produce     json
// @Param       member_id path string true "Member UUID"
// @Success     200 {object} map[string]any
// @Router      /api/v1/admin/messages/conversations/{member_id} [get]
func (h *AdminMessageHandler) GetConversation(c *fiber.Ctx) error {
	memberID, err := uuid.Parse(c.Params("member_id"))
	if err != nil {
		return utils.ErrorResponse(c, fiber.StatusBadRequest, "INVALID_ID", "Member ID must be a valid UUID", nil)
	}

	msgs, err := h.svc.GetConversation(c.UserContext(), memberID)
	if err != nil {
		h.log.ErrorContext(c.UserContext(), "get conversation", "error", err)
		return utils.ErrorResponse(c, fiber.StatusInternalServerError, "INTERNAL_ERROR", "Could not fetch conversation", nil)
	}

	return utils.SuccessResponse(c, fiber.StatusOK, msgs)
}

// ── helpers ───────────────────────────────────────────────────────────────────

func adminIDFromCtx(c *fiber.Ctx) (uuid.UUID, error) {
	return uuid.Parse(c.Locals("user_id").(string))
}
