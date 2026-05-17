package handlers_test

import (
	"context"
	"fmt"
	"net/http"
	"testing"
	"time"

	"github.com/asadlive84/fitness-care-bagerhat/internal/handlers"
	"github.com/asadlive84/fitness-care-bagerhat/internal/models"
	"github.com/asadlive84/fitness-care-bagerhat/internal/services"
	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"log/slog"
)

// ── fake plan service ─────────────────────────────────────────────────────────

type fakePlanSvc struct {
	createResult      *models.PlanTemplate
	createErr         error
	listWithSubResult []*models.PlanWithSubscribers
	listErr           error
	updateResult      *models.PlanTemplate
	updateErr         error
	deleteErr         error
}

func (f *fakePlanSvc) CreatePlan(_ context.Context, _ services.CreatePlanRequest) (*models.PlanTemplate, error) {
	return f.createResult, f.createErr
}
func (f *fakePlanSvc) ListPlansWithSubscribers(_ context.Context) ([]*models.PlanWithSubscribers, error) {
	return f.listWithSubResult, f.listErr
}
func (f *fakePlanSvc) UpdatePlan(_ context.Context, _ uuid.UUID, _ services.UpdatePlanRequest) (*models.PlanTemplate, error) {
	return f.updateResult, f.updateErr
}
func (f *fakePlanSvc) DeletePlan(_ context.Context, _ uuid.UUID) error {
	return f.deleteErr
}

func newPlanTestApp(svc *fakePlanSvc) *fiber.App {
	app := fiber.New()
	h := handlers.NewAdminPlanHandlerWithSvc(svc, slog.Default())
	app.Post("/plans",       h.CreatePlan)
	app.Get("/plans",        h.ListPlans)
	app.Patch("/plans/:id",  h.UpdatePlan)
	app.Delete("/plans/:id", h.DeletePlan)
	return app
}

func samplePlan() *models.PlanTemplate {
	return &models.PlanTemplate{
		ID:           uuid.New(),
		Name:         "Monthly Basic",
		DurationDays: 30,
		DefaultPrice: 1500,
		CreatedAt:    time.Now(),
		UpdatedAt:    time.Now(),
	}
}

// ── Tests ─────────────────────────────────────────────────────────────────────

func TestCreatePlan_Success(t *testing.T) {
	plan := samplePlan()
	app := newPlanTestApp(&fakePlanSvc{createResult: plan})

	resp := doRequest(t, app, http.MethodPost, "/plans", map[string]any{
		"name": "Monthly Basic", "duration_days": 30, "default_price": 1500,
	})
	require.Equal(t, http.StatusCreated, resp.StatusCode)
	body := decodeBody(t, resp)
	assert.True(t, body["success"].(bool))
	assert.Equal(t, "Monthly Basic", body["data"].(map[string]any)["name"])
}

func TestCreatePlan_ValidationError(t *testing.T) {
	app := newPlanTestApp(&fakePlanSvc{})
	// Missing required fields
	resp := doRequest(t, app, http.MethodPost, "/plans", map[string]any{"name": "X"})
	assert.Equal(t, http.StatusBadRequest, resp.StatusCode)
}

func TestListPlans_Success(t *testing.T) {
	plans := []*models.PlanWithSubscribers{
		{PlanTemplate: *samplePlan(), Subscribers: []models.PlanSubscriber{}},
		{PlanTemplate: *samplePlan(), Subscribers: []models.PlanSubscriber{}},
	}
	app := newPlanTestApp(&fakePlanSvc{listWithSubResult: plans})

	resp := doRequest(t, app, http.MethodGet, "/plans", nil)
	require.Equal(t, http.StatusOK, resp.StatusCode)
	body := decodeBody(t, resp)
	data := body["data"].([]any)
	assert.Len(t, data, 2)
}

func TestUpdatePlan_Success(t *testing.T) {
	plan := samplePlan()
	app := newPlanTestApp(&fakePlanSvc{updateResult: plan})

	resp := doRequest(t, app, http.MethodPatch, "/plans/"+plan.ID.String(), map[string]any{
		"name": "Updated Plan", "duration_days": 60, "default_price": 2500,
	})
	assert.Equal(t, http.StatusOK, resp.StatusCode)
}

func TestUpdatePlan_NotFound(t *testing.T) {
	app := newPlanTestApp(&fakePlanSvc{updateErr: services.ErrNotFound})
	resp := doRequest(t, app, http.MethodPatch, "/plans/"+uuid.NewString(), map[string]any{
		"name": "NonExistent Plan", "duration_days": 30, "default_price": 1000,
	})
	assert.Equal(t, http.StatusNotFound, resp.StatusCode)
}

func TestDeletePlan_Success(t *testing.T) {
	app := newPlanTestApp(&fakePlanSvc{})
	resp := doRequest(t, app, http.MethodDelete, "/plans/"+uuid.NewString(), nil)
	assert.Equal(t, http.StatusNoContent, resp.StatusCode)
}

func TestDeletePlan_FKConflict(t *testing.T) {
	err := fmt.Errorf("%w: has active subscriptions", services.ErrConflict)
	app := newPlanTestApp(&fakePlanSvc{deleteErr: err})
	resp := doRequest(t, app, http.MethodDelete, "/plans/"+uuid.NewString(), nil)
	assert.Equal(t, http.StatusConflict, resp.StatusCode)
}
