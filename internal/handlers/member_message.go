package handlers

import (
	"context"
	"log/slog"

	"github.com/asadlive84/fitness-care-bagerhat/internal/models"
	"github.com/asadlive84/fitness-care-bagerhat/internal/services"
	"github.com/asadlive84/fitness-care-bagerhat/internal/utils"
	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
)

type memberMsgSvc interface {
	GetMemberMessages(ctx context.Context, memberID uuid.UUID, page, limit int) ([]*models.Message, error)
	MemberSendMessage(ctx context.Context, memberID uuid.UUID, content string) (*models.Message, error)
}

// MemberMessageHandler holds HTTP handlers for member messaging.
type MemberMessageHandler struct {
	svc memberMsgSvc
	log *slog.Logger
}

// NewMemberMessageHandler creates a MemberMessageHandler.
func NewMemberMessageHandler(svc *services.MessageService, log *slog.Logger) *MemberMessageHandler {
	return &MemberMessageHandler{svc: svc, log: log}
}

// NewMemberMessageHandlerWithSvc injects any memberMsgSvc — used in tests.
func NewMemberMessageHandlerWithSvc(svc memberMsgSvc, log *slog.Logger) *MemberMessageHandler {
	return &MemberMessageHandler{svc: svc, log: log}
}

// ── DTOs ──────────────────────────────────────────────────────────────────────

type sendMessageReq struct {
	Content string `json:"content" validate:"required,min=1,max=2000"`
}

// ── Handlers ──────────────────────────────────────────────────────────────────

// GetMessages godoc
// @Summary     Get member messages (direct + broadcasts)
// @Tags        member/messages
// @Security    BearerAuth
// @Produce     json
// @Param       page  query int false "Page (default 1)"
// @Param       limit query int false "Limit (default 20)"
// @Success     200 {object} map[string]any
// @Router      /api/v1/member/messages [get]
func (h *MemberMessageHandler) GetMessages(c *fiber.Ctx) error {
	id, err := memberID(c)
	if err != nil {
		return utils.ErrorResponse(c, fiber.StatusUnauthorized, "UNAUTHORIZED", "Invalid token", nil)
	}

	page, limit := parsePagination(c)
	msgs, err := h.svc.GetMemberMessages(c.UserContext(), id, page, limit)
	if err != nil {
		h.log.ErrorContext(c.UserContext(), "get member messages", "error", err)
		return utils.ErrorResponse(c, fiber.StatusInternalServerError, "INTERNAL_ERROR", "Could not fetch messages", nil)
	}

	return utils.SuccessResponse(c, fiber.StatusOK, msgs)
}

// SendMessage godoc
// @Summary     Send message to admin
// @Tags        member/messages
// @Security    BearerAuth
// @Accept      json
// @Produce     json
// @Param       body body sendMessageReq true "Message content"
// @Success     201 {object} map[string]any
// @Router      /api/v1/member/messages [post]
func (h *MemberMessageHandler) SendMessage(c *fiber.Ctx) error {
	id, err := memberID(c)
	if err != nil {
		return utils.ErrorResponse(c, fiber.StatusUnauthorized, "UNAUTHORIZED", "Invalid token", nil)
	}

	var req sendMessageReq
	if !parseAndValidate(c, &req) {
		return nil
	}

	msg, err := h.svc.MemberSendMessage(c.UserContext(), id, req.Content)
	if err != nil {
		h.log.ErrorContext(c.UserContext(), "send member message", "error", err)
		return utils.ErrorResponse(c, fiber.StatusInternalServerError, "INTERNAL_ERROR", "Could not send message", nil)
	}

	return utils.SuccessResponse(c, fiber.StatusCreated, msg)
}
