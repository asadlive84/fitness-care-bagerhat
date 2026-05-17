package handlers_test

import (
	"context"
	"log/slog"
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
)

// ── fake subscription service ─────────────────────────────────────────────────

type fakeSubSvc struct {
	assignResult *models.Subscription
	assignErr    error
	listResult   []*models.Subscription
	listErr      error
	updateResult *models.Subscription
	updateErr    error
}

func (f *fakeSubSvc) AssignPlan(_ context.Context, _ uuid.UUID, _ services.AssignPlanRequest) (*models.Subscription, error) {
	return f.assignResult, f.assignErr
}
func (f *fakeSubSvc) ListSubscriptions(_ context.Context, _ uuid.UUID) ([]*models.Subscription, error) {
	return f.listResult, f.listErr
}
func (f *fakeSubSvc) UpdateActive(_ context.Context, _ uuid.UUID, _ services.UpdateActiveRequest) (*models.Subscription, error) {
	return f.updateResult, f.updateErr
}

func newSubTestApp(svc *fakeSubSvc) *fiber.App {
	app := fiber.New()
	h := handlers.NewAdminSubscriptionHandlerWithSvc(svc, slog.Default())
	app.Post("/members/:id/subscriptions",         h.AssignPlan)
	app.Get("/members/:id/subscriptions",          h.ListSubscriptions)
	app.Patch("/members/:id/subscriptions/active", h.UpdateActive)
	return app
}

func sampleSubscription(memberID uuid.UUID) *models.Subscription {
	return &models.Subscription{
		ID:             uuid.New(),
		MemberID:       memberID,
		PlanTemplateID: uuid.New(),
		StartDate:      time.Now(),
		EndDate:        time.Now().AddDate(0, 1, 0),
		FinalPrice:     1500,
		Status:         "active",
		CreatedAt:      time.Now(),
	}
}

// ── Tests ─────────────────────────────────────────────────────────────────────

func TestAssignPlan_Success(t *testing.T) {
	memberID := uuid.New()
	sub := sampleSubscription(memberID)
	app := newSubTestApp(&fakeSubSvc{assignResult: sub})

	resp := doRequest(t, app, http.MethodPost,
		"/members/"+memberID.String()+"/subscriptions",
		map[string]any{
			"plan_template_id": uuid.NewString(),
		},
	)
	require.Equal(t, http.StatusCreated, resp.StatusCode)
	body := decodeBody(t, resp)
	assert.True(t, body["success"].(bool))
}

func TestAssignPlan_MemberInactive(t *testing.T) {
	memberID := uuid.New()
	app := newSubTestApp(&fakeSubSvc{assignErr: services.ErrMemberInactive})

	resp := doRequest(t, app, http.MethodPost,
		"/members/"+memberID.String()+"/subscriptions",
		map[string]any{"plan_template_id": uuid.NewString()},
	)
	assert.Equal(t, http.StatusUnprocessableEntity, resp.StatusCode)
}

func TestAssignPlan_ValidationError(t *testing.T) {
	app := newSubTestApp(&fakeSubSvc{})
	resp := doRequest(t, app, http.MethodPost,
		"/members/"+uuid.NewString()+"/subscriptions",
		map[string]any{}, // missing plan_template_id
	)
	assert.Equal(t, http.StatusBadRequest, resp.StatusCode)
}

func TestListSubscriptions_Success(t *testing.T) {
	memberID := uuid.New()
	subs := []*models.Subscription{sampleSubscription(memberID), sampleSubscription(memberID)}
	app := newSubTestApp(&fakeSubSvc{listResult: subs})

	resp := doRequest(t, app, http.MethodGet,
		"/members/"+memberID.String()+"/subscriptions", nil)
	require.Equal(t, http.StatusOK, resp.StatusCode)
	body := decodeBody(t, resp)
	data := body["data"].([]any)
	assert.Len(t, data, 2)
}

func TestUpdateActive_Success(t *testing.T) {
	memberID := uuid.New()
	sub := sampleSubscription(memberID)
	app := newSubTestApp(&fakeSubSvc{updateResult: sub})

	resp := doRequest(t, app, http.MethodPatch,
		"/members/"+memberID.String()+"/subscriptions/active",
		map[string]any{"start_date": "2026-01-01", "end_date": "2026-12-31", "final_price": 1200},
	)
	assert.Equal(t, http.StatusOK, resp.StatusCode)
}

func TestUpdateActive_NotFound(t *testing.T) {
	app := newSubTestApp(&fakeSubSvc{updateErr: services.ErrNotFound})
	resp := doRequest(t, app, http.MethodPatch,
		"/members/"+uuid.NewString()+"/subscriptions/active",
		map[string]any{"start_date": "2026-01-01", "end_date": "2026-12-31", "final_price": 1200},
	)
	assert.Equal(t, http.StatusNotFound, resp.StatusCode)
}
