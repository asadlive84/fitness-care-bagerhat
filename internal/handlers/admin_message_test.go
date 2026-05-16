package handlers_test

import (
	"context"
	"log/slog"
	"net/http"
	"testing"
	"time"

	"github.com/asadlive84/fitness-care-bagerhat/internal/handlers"
	"github.com/asadlive84/fitness-care-bagerhat/internal/models"
	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// ── fake admin message service ────────────────────────────────────────────────

type fakeAdminMsgSvc struct {
	broadcastResult *models.Message
	broadcastErr    error
	directResult    *models.Message
	directErr       error
	convResult      []*models.ConversationSummary
	convErr         error
	msgResult       []*models.Message
	msgErr          error
}

func (f *fakeAdminMsgSvc) SendBroadcast(_ context.Context, _ uuid.UUID, _, _ string) (*models.Message, error) {
	return f.broadcastResult, f.broadcastErr
}
func (f *fakeAdminMsgSvc) SendDirect(_ context.Context, _, _ uuid.UUID, _ string) (*models.Message, error) {
	return f.directResult, f.directErr
}
func (f *fakeAdminMsgSvc) GetConversations(_ context.Context) ([]*models.ConversationSummary, error) {
	return f.convResult, f.convErr
}
func (f *fakeAdminMsgSvc) GetConversation(_ context.Context, _ uuid.UUID) ([]*models.Message, error) {
	return f.msgResult, f.msgErr
}

func newAdminMsgTestApp(svc *fakeAdminMsgSvc) *fiber.App {
	app := fiber.New()
	h := handlers.NewAdminMessageHandlerWithSvc(svc, slog.Default())
	withAdmin := func(c *fiber.Ctx) error {
		c.Locals("user_id", uuid.NewString())
		return c.Next()
	}
	app.Post("/messages/broadcast",               withAdmin, h.SendBroadcast)
	app.Post("/messages/direct",                  withAdmin, h.SendDirect)
	app.Get("/messages/conversations",            h.ListConversations)
	app.Get("/messages/conversations/:member_id", h.GetConversation)
	return app
}

func sampleMessage(senderID uuid.UUID, role string) *models.Message {
	return &models.Message{
		ID:         uuid.New(),
		SenderID:   senderID,
		SenderRole: role,
		Content:    "Test message",
		SentAt:     time.Now(),
	}
}

// ── Tests ─────────────────────────────────────────────────────────────────────

func TestSendBroadcast_Success(t *testing.T) {
	adminID := uuid.New()
	msg := sampleMessage(adminID, "admin")
	filter := "active"
	msg.BroadcastFilter = &filter
	msg.IsBroadcast = true

	app := newAdminMsgTestApp(&fakeAdminMsgSvc{broadcastResult: msg})
	resp := doRequest(t, app, http.MethodPost, "/messages/broadcast", map[string]any{
		"content": "All active members: gym closes early today", "broadcast_filter": "active",
	})
	require.Equal(t, http.StatusCreated, resp.StatusCode)
	body := decodeBody(t, resp)
	assert.True(t, body["success"].(bool))
}

func TestSendBroadcast_InvalidFilter(t *testing.T) {
	app := newAdminMsgTestApp(&fakeAdminMsgSvc{})
	resp := doRequest(t, app, http.MethodPost, "/messages/broadcast", map[string]any{
		"content": "Hello", "broadcast_filter": "vip", // not in oneof
	})
	assert.Equal(t, http.StatusBadRequest, resp.StatusCode)
}

func TestSendBroadcast_ValidationError(t *testing.T) {
	app := newAdminMsgTestApp(&fakeAdminMsgSvc{})
	// Missing required fields
	resp := doRequest(t, app, http.MethodPost, "/messages/broadcast", map[string]any{})
	assert.Equal(t, http.StatusBadRequest, resp.StatusCode)
}

func TestSendDirect_Success(t *testing.T) {
	adminID := uuid.New()
	msg := sampleMessage(adminID, "admin")
	app := newAdminMsgTestApp(&fakeAdminMsgSvc{directResult: msg})

	resp := doRequest(t, app, http.MethodPost, "/messages/direct", map[string]any{
		"member_id": uuid.NewString(), "content": "Hello Karim!",
	})
	require.Equal(t, http.StatusCreated, resp.StatusCode)
}

func TestSendDirect_ValidationError(t *testing.T) {
	app := newAdminMsgTestApp(&fakeAdminMsgSvc{})
	resp := doRequest(t, app, http.MethodPost, "/messages/direct", map[string]any{
		"member_id": "not-a-uuid", "content": "Hello",
	})
	assert.Equal(t, http.StatusBadRequest, resp.StatusCode)
}

func TestListConversations_Success(t *testing.T) {
	convs := []*models.ConversationSummary{
		{MemberID: uuid.New(), LastMessage: "Hi", LastSentAt: time.Now(), SenderRole: "member"},
	}
	app := newAdminMsgTestApp(&fakeAdminMsgSvc{convResult: convs})

	resp := doRequest(t, app, http.MethodGet, "/messages/conversations", nil)
	require.Equal(t, http.StatusOK, resp.StatusCode)
	body := decodeBody(t, resp)
	data := body["data"].([]any)
	assert.Len(t, data, 1)
}

func TestGetConversation_Success(t *testing.T) {
	memberID := uuid.New()
	msgs := []*models.Message{sampleMessage(memberID, "member"), sampleMessage(uuid.New(), "admin")}
	app := newAdminMsgTestApp(&fakeAdminMsgSvc{msgResult: msgs})

	resp := doRequest(t, app, http.MethodGet, "/messages/conversations/"+memberID.String(), nil)
	require.Equal(t, http.StatusOK, resp.StatusCode)
	body := decodeBody(t, resp)
	data := body["data"].([]any)
	assert.Len(t, data, 2)
}

func TestGetConversation_InvalidUUID(t *testing.T) {
	app := newAdminMsgTestApp(&fakeAdminMsgSvc{})
	resp := doRequest(t, app, http.MethodGet, "/messages/conversations/not-a-uuid", nil)
	assert.Equal(t, http.StatusBadRequest, resp.StatusCode)
}
