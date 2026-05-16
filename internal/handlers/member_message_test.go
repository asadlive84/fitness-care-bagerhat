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

// ── fake member message service ───────────────────────────────────────────────

type fakeMemberMsgSvc struct {
	getResult  []*models.Message
	getErr     error
	sendResult *models.Message
	sendErr    error
}

func (f *fakeMemberMsgSvc) GetMemberMessages(_ context.Context, _ uuid.UUID, _, _ int) ([]*models.Message, error) {
	return f.getResult, f.getErr
}
func (f *fakeMemberMsgSvc) MemberSendMessage(_ context.Context, _ uuid.UUID, _ string) (*models.Message, error) {
	return f.sendResult, f.sendErr
}

func newMemberMsgTestApp(svc *fakeMemberMsgSvc) *fiber.App {
	app := fiber.New()
	h := handlers.NewMemberMessageHandlerWithSvc(svc, slog.Default())
	withMember := func(c *fiber.Ctx) error {
		c.Locals("user_id", uuid.NewString())
		return c.Next()
	}
	app.Get("/member/messages",  withMember, h.GetMessages)
	app.Post("/member/messages", withMember, h.SendMessage)
	return app
}

// ── Tests ─────────────────────────────────────────────────────────────────────

func TestGetMemberMessages_Success(t *testing.T) {
	msgs := []*models.Message{
		{ID: uuid.New(), SenderRole: "admin", Content: "Welcome!", SentAt: time.Now()},
		{ID: uuid.New(), SenderRole: "admin", Content: "Gym closes at 9pm", IsBroadcast: true, SentAt: time.Now()},
	}
	app := newMemberMsgTestApp(&fakeMemberMsgSvc{getResult: msgs})

	resp := doRequest(t, app, http.MethodGet, "/member/messages", nil)
	require.Equal(t, http.StatusOK, resp.StatusCode)
	body := decodeBody(t, resp)
	data := body["data"].([]any)
	assert.Len(t, data, 2)
}

func TestGetMemberMessages_Empty(t *testing.T) {
	app := newMemberMsgTestApp(&fakeMemberMsgSvc{getResult: []*models.Message{}})
	resp := doRequest(t, app, http.MethodGet, "/member/messages", nil)
	require.Equal(t, http.StatusOK, resp.StatusCode)
}

func TestSendMemberMessage_Success(t *testing.T) {
	msg := &models.Message{ID: uuid.New(), SenderRole: "member", Content: "Hello admin", SentAt: time.Now()}
	app := newMemberMsgTestApp(&fakeMemberMsgSvc{sendResult: msg})

	resp := doRequest(t, app, http.MethodPost, "/member/messages", map[string]any{
		"content": "Hello admin, I have a question",
	})
	require.Equal(t, http.StatusCreated, resp.StatusCode)
	body := decodeBody(t, resp)
	assert.Equal(t, "member", body["data"].(map[string]any)["sender_role"])
}

func TestSendMemberMessage_ValidationError(t *testing.T) {
	app := newMemberMsgTestApp(&fakeMemberMsgSvc{})
	// Empty content
	resp := doRequest(t, app, http.MethodPost, "/member/messages", map[string]any{"content": ""})
	assert.Equal(t, http.StatusBadRequest, resp.StatusCode)
}

func TestSendMemberMessage_EmptyBody(t *testing.T) {
	app := newMemberMsgTestApp(&fakeMemberMsgSvc{})
	resp := doRequest(t, app, http.MethodPost, "/member/messages", map[string]any{})
	assert.Equal(t, http.StatusBadRequest, resp.StatusCode)
}
