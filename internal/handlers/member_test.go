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

// ── Fake services ─────────────────────────────────────────────────────────────

type fakeProfileSvc struct {
	getResult    *models.Member
	getErr       error
	updateResult *models.Member
	updateErr    error
}

func (f *fakeProfileSvc) GetMember(_ context.Context, _ uuid.UUID) (*models.Member, error) {
	return f.getResult, f.getErr
}
func (f *fakeProfileSvc) UpdateMember(_ context.Context, _ uuid.UUID, _ services.UpdateMemberRequest) (*models.Member, error) {
	return f.updateResult, f.updateErr
}

type fakeMemberSubSvc struct {
	result *models.EnrichedSubscription
	err    error
}

func (f *fakeMemberSubSvc) GetActiveSubscriptionEnriched(_ context.Context, _ uuid.UUID) (*models.EnrichedSubscription, error) {
	return f.result, f.err
}

type fakeMemberPaymentSvc struct {
	result []*models.Payment
	err    error
}

func (f *fakeMemberPaymentSvc) ListMemberPayments(_ context.Context, _ uuid.UUID, _ models.PaymentFilter) ([]*models.Payment, error) {
	return f.result, f.err
}

type fakeWeightSvc struct {
	logResult  *models.WeightLog
	logErr     error
	listResult []models.WeightLog
	listErr    error
}

func (f *fakeWeightSvc) LogWeight(_ context.Context, _ uuid.UUID, _ float64, _ time.Time) (*models.WeightLog, error) {
	return f.logResult, f.logErr
}
func (f *fakeWeightSvc) ListWeightLogs(_ context.Context, _ uuid.UUID, _, _ *time.Time) ([]models.WeightLog, error) {
	return f.listResult, f.listErr
}

type fakeWorkoutSvc struct {
	logResult  *models.WorkoutLog
	logErr     error
	listResult []models.WorkoutLog
	listErr    error
}

func (f *fakeWorkoutSvc) LogWorkout(_ context.Context, _ uuid.UUID, _ string, _ time.Time) (*models.WorkoutLog, error) {
	return f.logResult, f.logErr
}
func (f *fakeWorkoutSvc) ListWorkoutLogs(_ context.Context, _ uuid.UUID, _, _ int) ([]models.WorkoutLog, error) {
	return f.listResult, f.listErr
}

type fakeDietSvc struct {
	logResult  *models.DietLog
	logErr     error
	listResult []models.DietLog
	listErr    error
}

func (f *fakeDietSvc) LogDiet(_ context.Context, _ uuid.UUID, _ string, _ time.Time) (*models.DietLog, error) {
	return f.logResult, f.logErr
}
func (f *fakeDietSvc) ListDietLogs(_ context.Context, _ uuid.UUID, _, _ int) ([]models.DietLog, error) {
	return f.listResult, f.listErr
}

// ── App factory ───────────────────────────────────────────────────────────────

func newMemberTestApp(
	profile *fakeProfileSvc,
	subs *fakeMemberSubSvc,
	payments *fakeMemberPaymentSvc,
	weights *fakeWeightSvc,
	workouts *fakeWorkoutSvc,
	diets *fakeDietSvc,
) *fiber.App {
	app := fiber.New()
	h := handlers.NewMemberHandlerWithDeps(profile, subs, payments, weights, workouts, diets, slog.Default())

	// Inject a fake member ID via middleware (simulating JWT).
	memberID := uuid.NewString()
	withMember := func(c *fiber.Ctx) error {
		c.Locals("user_id", memberID)
		return c.Next()
	}

	app.Get("/member/profile",      withMember, h.GetProfile)
	app.Patch("/member/profile",    withMember, h.UpdateProfile)
	app.Get("/member/subscription", withMember, h.GetActiveSubscription)
	app.Get("/member/payments",     withMember, h.GetPayments)
	app.Post("/member/weight-logs", withMember, h.LogWeight)
	app.Get("/member/weight-logs",  withMember, h.ListWeightLogs)
	app.Post("/member/workout-logs", withMember, h.LogWorkout)
	app.Get("/member/workout-logs",  withMember, h.ListWorkoutLogs)
	app.Post("/member/diet-logs",   withMember, h.LogDiet)
	app.Get("/member/diet-logs",    withMember, h.ListDietLogs)
	return app
}

func defaultMemberApp(
	profile *fakeProfileSvc,
	sub *fakeMemberSubSvc,
	payment *fakeMemberPaymentSvc,
	weight *fakeWeightSvc,
	workout *fakeWorkoutSvc,
	diet *fakeDietSvc,
) *fiber.App {
	return newMemberTestApp(profile, sub, payment, weight, workout, diet)
}

// ── Tests ─────────────────────────────────────────────────────────────────────

func TestGetProfile_Success(t *testing.T) {
	m := sampleMember()
	app := defaultMemberApp(&fakeProfileSvc{getResult: m}, &fakeMemberSubSvc{}, &fakeMemberPaymentSvc{}, &fakeWeightSvc{}, &fakeWorkoutSvc{}, &fakeDietSvc{})

	resp := doRequest(t, app, http.MethodGet, "/member/profile", nil)
	require.Equal(t, http.StatusOK, resp.StatusCode)
	body := decodeBody(t, resp)
	assert.Equal(t, m.Name, body["data"].(map[string]any)["name"])
}

func TestUpdateProfile_Success(t *testing.T) {
	m := sampleMember()
	app := defaultMemberApp(&fakeProfileSvc{getResult: m, updateResult: m}, &fakeMemberSubSvc{}, &fakeMemberPaymentSvc{}, &fakeWeightSvc{}, &fakeWorkoutSvc{}, &fakeDietSvc{})

	resp := doRequest(t, app, http.MethodPatch, "/member/profile", map[string]any{
		"name": "Updated Name",
	})
	assert.Equal(t, http.StatusOK, resp.StatusCode)
}

func TestUpdateProfile_ValidationError(t *testing.T) {
	app := defaultMemberApp(&fakeProfileSvc{}, &fakeMemberSubSvc{}, &fakeMemberPaymentSvc{}, &fakeWeightSvc{}, &fakeWorkoutSvc{}, &fakeDietSvc{})
	resp := doRequest(t, app, http.MethodPatch, "/member/profile", map[string]any{"name": "A"}) // too short
	assert.Equal(t, http.StatusBadRequest, resp.StatusCode)
}

func TestGetActiveSubscription_Success(t *testing.T) {
	sub := &models.EnrichedSubscription{
		ID: uuid.New(), PlanName: "Monthly", PlanPrice: 500, FinalPrice: 500,
		StartDate: time.Now(), EndDate: time.Now().AddDate(0, 1, 0), Status: "active",
	}
	app := defaultMemberApp(&fakeProfileSvc{}, &fakeMemberSubSvc{result: sub}, &fakeMemberPaymentSvc{}, &fakeWeightSvc{}, &fakeWorkoutSvc{}, &fakeDietSvc{})

	resp := doRequest(t, app, http.MethodGet, "/member/subscription", nil)
	assert.Equal(t, http.StatusOK, resp.StatusCode)
}

func TestGetActiveSubscription_None(t *testing.T) {
	// nil result = 200 with null data (no active subscription)
	app := defaultMemberApp(&fakeProfileSvc{}, &fakeMemberSubSvc{result: nil}, &fakeMemberPaymentSvc{}, &fakeWeightSvc{}, &fakeWorkoutSvc{}, &fakeDietSvc{})
	resp := doRequest(t, app, http.MethodGet, "/member/subscription", nil)
	assert.Equal(t, http.StatusOK, resp.StatusCode)
}

func TestGetPayments_Success(t *testing.T) {
	memberID := uuid.New()
	pmts := []*models.Payment{samplePayment(memberID)}
	app := defaultMemberApp(&fakeProfileSvc{}, &fakeMemberSubSvc{}, &fakeMemberPaymentSvc{result: pmts}, &fakeWeightSvc{}, &fakeWorkoutSvc{}, &fakeDietSvc{})

	resp := doRequest(t, app, http.MethodGet, "/member/payments", nil)
	require.Equal(t, http.StatusOK, resp.StatusCode)
	body := decodeBody(t, resp)
	assert.Len(t, body["data"].([]any), 1)
}

func TestLogWeight_Success(t *testing.T) {
	entry := &models.WeightLog{ID: uuid.New(), WeightKg: 72.5, LoggedAt: time.Now()}
	app := defaultMemberApp(&fakeProfileSvc{}, &fakeMemberSubSvc{}, &fakeMemberPaymentSvc{}, &fakeWeightSvc{logResult: entry}, &fakeWorkoutSvc{}, &fakeDietSvc{})

	resp := doRequest(t, app, http.MethodPost, "/member/weight-logs", map[string]any{"weight_kg": 72.5})
	require.Equal(t, http.StatusCreated, resp.StatusCode)
	body := decodeBody(t, resp)
	assert.Equal(t, float64(72.5), body["data"].(map[string]any)["weight_kg"])
}

func TestLogWeight_ValidationError(t *testing.T) {
	app := defaultMemberApp(&fakeProfileSvc{}, &fakeMemberSubSvc{}, &fakeMemberPaymentSvc{}, &fakeWeightSvc{}, &fakeWorkoutSvc{}, &fakeDietSvc{})
	resp := doRequest(t, app, http.MethodPost, "/member/weight-logs", map[string]any{"weight_kg": -5}) // negative
	assert.Equal(t, http.StatusBadRequest, resp.StatusCode)
}

func TestListWeightLogs_Success(t *testing.T) {
	logs := []models.WeightLog{{ID: uuid.New(), WeightKg: 72.5, LoggedAt: time.Now()}}
	app := defaultMemberApp(&fakeProfileSvc{}, &fakeMemberSubSvc{}, &fakeMemberPaymentSvc{}, &fakeWeightSvc{listResult: logs}, &fakeWorkoutSvc{}, &fakeDietSvc{})

	resp := doRequest(t, app, http.MethodGet, "/member/weight-logs", nil)
	assert.Equal(t, http.StatusOK, resp.StatusCode)
}

func TestListWeightLogs_WithDateRange(t *testing.T) {
	app := defaultMemberApp(&fakeProfileSvc{}, &fakeMemberSubSvc{}, &fakeMemberPaymentSvc{}, &fakeWeightSvc{}, &fakeWorkoutSvc{}, &fakeDietSvc{})
	resp := doRequest(t, app, http.MethodGet, "/member/weight-logs?from=2026-01-01&to=2026-05-31", nil)
	assert.Equal(t, http.StatusOK, resp.StatusCode)
}

func TestLogWorkout_Success(t *testing.T) {
	entry := &models.WorkoutLog{ID: uuid.New(), Content: "5km run", LoggedAt: time.Now()}
	app := defaultMemberApp(&fakeProfileSvc{}, &fakeMemberSubSvc{}, &fakeMemberPaymentSvc{}, &fakeWeightSvc{}, &fakeWorkoutSvc{logResult: entry}, &fakeDietSvc{})

	resp := doRequest(t, app, http.MethodPost, "/member/workout-logs", map[string]any{"content": "5km run"})
	require.Equal(t, http.StatusCreated, resp.StatusCode)
}

func TestListWorkoutLogs_Success(t *testing.T) {
	app := defaultMemberApp(&fakeProfileSvc{}, &fakeMemberSubSvc{}, &fakeMemberPaymentSvc{}, &fakeWeightSvc{}, &fakeWorkoutSvc{listResult: []models.WorkoutLog{}}, &fakeDietSvc{})
	resp := doRequest(t, app, http.MethodGet, "/member/workout-logs", nil)
	assert.Equal(t, http.StatusOK, resp.StatusCode)
}

func TestLogDiet_Success(t *testing.T) {
	entry := &models.DietLog{ID: uuid.New(), Content: "Oats with milk", LoggedAt: time.Now()}
	app := defaultMemberApp(&fakeProfileSvc{}, &fakeMemberSubSvc{}, &fakeMemberPaymentSvc{}, &fakeWeightSvc{}, &fakeWorkoutSvc{}, &fakeDietSvc{logResult: entry})

	resp := doRequest(t, app, http.MethodPost, "/member/diet-logs", map[string]any{"content": "Oats with milk"})
	require.Equal(t, http.StatusCreated, resp.StatusCode)
}

func TestListDietLogs_Success(t *testing.T) {
	app := defaultMemberApp(&fakeProfileSvc{}, &fakeMemberSubSvc{}, &fakeMemberPaymentSvc{}, &fakeWeightSvc{}, &fakeWorkoutSvc{}, &fakeDietSvc{listResult: []models.DietLog{}})
	resp := doRequest(t, app, http.MethodGet, "/member/diet-logs", nil)
	assert.Equal(t, http.StatusOK, resp.StatusCode)
}
