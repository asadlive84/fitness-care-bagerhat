package handlers_test

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/asadlive84/fitness-care-bagerhat/internal/handlers"
	"github.com/asadlive84/fitness-care-bagerhat/internal/models"
	"github.com/asadlive84/fitness-care-bagerhat/internal/services"
	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// ── Fake service ──────────────────────────────────────────────────────────────

type fakeMemberSvc struct {
	createResult *services.CreateMemberResult
	createErr    error
	getResult    *models.Member
	getErr       error
	listResult   []*models.Member
	listTotal    int64
	listErr      error
	updateResult *models.Member
	updateErr    error
	statusErr    error
}

func (f *fakeMemberSvc) CreateMember(_ context.Context, _ services.CreateMemberRequest) (*services.CreateMemberResult, error) {
	return f.createResult, f.createErr
}
func (f *fakeMemberSvc) GetMember(_ context.Context, _ uuid.UUID) (*models.Member, error) {
	return f.getResult, f.getErr
}
func (f *fakeMemberSvc) ListMembers(_ context.Context, _ models.MemberFilter) ([]*models.Member, int64, error) {
	return f.listResult, f.listTotal, f.listErr
}
func (f *fakeMemberSvc) ListExpiringSoon(_ context.Context) ([]*models.Member, error) {
	return f.listResult, f.listErr
}
func (f *fakeMemberSvc) UpdateMember(_ context.Context, _ uuid.UUID, _ services.UpdateMemberRequest) (*models.Member, error) {
	return f.updateResult, f.updateErr
}
func (f *fakeMemberSvc) UpdateMemberStatus(_ context.Context, _ uuid.UUID, _ string) error {
	return f.statusErr
}

// ── Test app factory ──────────────────────────────────────────────────────────

func newTestApp(svc *fakeMemberSvc) *fiber.App {
	app := fiber.New(fiber.Config{ErrorHandler: func(c *fiber.Ctx, err error) error {
		return c.Status(500).JSON(fiber.Map{"error": err.Error()})
	}})

	h := handlers.NewAdminMemberHandlerWithSvc(svc, slog.Default())
	app.Post("/admin/members", h.CreateMember)
	app.Get("/admin/members", h.ListMembers)
	app.Get("/admin/members/:id", h.GetMember)
	app.Patch("/admin/members/:id", h.UpdateMember)
	app.Patch("/admin/members/:id/status", h.UpdateMemberStatus)
	return app
}

func doRequest(t *testing.T, app *fiber.App, method, path string, body any) *http.Response {
	t.Helper()
	var r io.Reader
	if body != nil {
		b, _ := json.Marshal(body)
		r = bytes.NewReader(b)
	}
	req := httptest.NewRequest(method, path, r)
	req.Header.Set("Content-Type", "application/json")
	resp, err := app.Test(req, 3000)
	require.NoError(t, err)
	return resp
}

func decodeBody(t *testing.T, resp *http.Response) map[string]any {
	t.Helper()
	var out map[string]any
	require.NoError(t, json.NewDecoder(resp.Body).Decode(&out))
	return out
}

func sampleMember() *models.Member {
	return &models.Member{
		ID:        uuid.New(),
		Name:      "Rahim Uddin",
		Phone:     "01711000001",
		Status:    "active",
		JoinDate:  time.Now(),
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}
}

// ── Tests ─────────────────────────────────────────────────────────────────────

func TestCreateMember_Success(t *testing.T) {
	m := sampleMember()
	svc := &fakeMemberSvc{createResult: &services.CreateMemberResult{Member: m, TempPassword: "Abc12345"}}
	resp := doRequest(t, newTestApp(svc), http.MethodPost, "/admin/members", map[string]any{
		"name": "Rahim Uddin", "phone": "01711000001",
	})

	assert.Equal(t, http.StatusCreated, resp.StatusCode)
	body := decodeBody(t, resp)
	assert.True(t, body["success"].(bool))
	data := body["data"].(map[string]any)
	assert.Equal(t, "Abc12345", data["temp_password"])
}

func TestCreateMember_ValidationError(t *testing.T) {
	resp := doRequest(t, newTestApp(&fakeMemberSvc{}), http.MethodPost, "/admin/members", map[string]any{
		"name": "A", // too short
	})
	assert.Equal(t, http.StatusBadRequest, resp.StatusCode)
	body := decodeBody(t, resp)
	assert.False(t, body["success"].(bool))
}

func TestCreateMember_Conflict(t *testing.T) {
	svc := &fakeMemberSvc{createErr: fmt.Errorf("%w: phone already registered", services.ErrConflict)}
	resp := doRequest(t, newTestApp(svc), http.MethodPost, "/admin/members", map[string]any{
		"name": "Rahim Uddin", "phone": "01711000001",
	})
	assert.Equal(t, http.StatusConflict, resp.StatusCode)
}

func TestGetMember_Success(t *testing.T) {
	m := sampleMember()
	svc := &fakeMemberSvc{getResult: m}
	resp := doRequest(t, newTestApp(svc), http.MethodGet, "/admin/members/"+m.ID.String(), nil)

	assert.Equal(t, http.StatusOK, resp.StatusCode)
	body := decodeBody(t, resp)
	data := body["data"].(map[string]any)
	assert.Equal(t, m.Name, data["name"])
}

func TestGetMember_NotFound(t *testing.T) {
	svc := &fakeMemberSvc{getErr: services.ErrNotFound}
	resp := doRequest(t, newTestApp(svc), http.MethodGet, "/admin/members/"+uuid.NewString(), nil)
	assert.Equal(t, http.StatusNotFound, resp.StatusCode)
}

func TestGetMember_InvalidUUID(t *testing.T) {
	resp := doRequest(t, newTestApp(&fakeMemberSvc{}), http.MethodGet, "/admin/members/not-a-uuid", nil)
	assert.Equal(t, http.StatusBadRequest, resp.StatusCode)
}

func TestListMembers_Success(t *testing.T) {
	svc := &fakeMemberSvc{listResult: []*models.Member{sampleMember(), sampleMember()}, listTotal: 2}
	resp := doRequest(t, newTestApp(svc), http.MethodGet, "/admin/members?page=1&limit=20", nil)

	assert.Equal(t, http.StatusOK, resp.StatusCode)
	body := decodeBody(t, resp)
	assert.True(t, body["success"].(bool))
	meta := body["meta"].(map[string]any)
	assert.Equal(t, float64(1), meta["page"])
	assert.Equal(t, float64(2), meta["total"])
}

func TestListMembers_ExpiringSoon(t *testing.T) {
	svc := &fakeMemberSvc{listResult: []*models.Member{sampleMember()}}
	resp := doRequest(t, newTestApp(svc), http.MethodGet, "/admin/members?expiring_soon=true", nil)
	assert.Equal(t, http.StatusOK, resp.StatusCode)
}

func TestUpdateMember_Success(t *testing.T) {
	m := sampleMember()
	svc := &fakeMemberSvc{updateResult: m}
	resp := doRequest(t, newTestApp(svc), http.MethodPatch, "/admin/members/"+m.ID.String(), map[string]any{
		"name": "Updated Name", "phone": "01722000002",
	})
	assert.Equal(t, http.StatusOK, resp.StatusCode)
}

func TestUpdateMemberStatus_Success(t *testing.T) {
	svc := &fakeMemberSvc{}
	resp := doRequest(t, newTestApp(svc), http.MethodPatch,
		"/admin/members/"+uuid.NewString()+"/status",
		map[string]any{"status": "inactive"},
	)
	assert.Equal(t, http.StatusNoContent, resp.StatusCode)
}

func TestUpdateMemberStatus_InvalidValue(t *testing.T) {
	resp := doRequest(t, newTestApp(&fakeMemberSvc{}), http.MethodPatch,
		"/admin/members/"+uuid.NewString()+"/status",
		map[string]any{"status": "banned"}, // not in oneof
	)
	assert.Equal(t, http.StatusBadRequest, resp.StatusCode)
}
