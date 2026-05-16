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

// ── fake payment service ──────────────────────────────────────────────────────

type fakePaymentSvc struct {
	recordResult  *models.Payment
	recordErr     error
	listResult    []*models.Payment
	listErr       error
	summaryResult *models.PaymentSummary
	summaryErr    error
}

func (f *fakePaymentSvc) RecordPayment(_ context.Context, _ services.RecordPaymentRequest) (*models.Payment, error) {
	return f.recordResult, f.recordErr
}
func (f *fakePaymentSvc) ListMemberPayments(_ context.Context, _ uuid.UUID, _ models.PaymentFilter) ([]*models.Payment, error) {
	return f.listResult, f.listErr
}
func (f *fakePaymentSvc) GetMonthlySummary(_ context.Context, _ time.Time) (*models.PaymentSummary, error) {
	return f.summaryResult, f.summaryErr
}

func newPaymentTestApp(svc *fakePaymentSvc) *fiber.App {
	app := fiber.New()
	h := handlers.NewAdminPaymentHandlerWithSvc(svc, slog.Default())

	// Simulate JWT middleware by pre-setting user_id in locals.
	withAdmin := func(c *fiber.Ctx) error {
		c.Locals("user_id", uuid.NewString())
		return c.Next()
	}

	app.Post("/payments",            withAdmin, h.RecordPayment)
	app.Get("/payments/summary",     h.GetPaymentSummary)
	app.Get("/members/:id/payments", h.ListMemberPayments)
	return app
}

func samplePayment(memberID uuid.UUID) *models.Payment {
	return &models.Payment{
		ID:                uuid.New(),
		MemberID:          memberID,
		SubscriptionID:    uuid.New(),
		Amount:            1500,
		Method:            "Cash",
		PaidAt:            time.Now(),
		RecordedByAdminID: uuid.New(),
		CreatedAt:         time.Now(),
	}
}

// ── Tests ─────────────────────────────────────────────────────────────────────

func TestRecordPayment_Success(t *testing.T) {
	memberID := uuid.New()
	payment := samplePayment(memberID)
	app := newPaymentTestApp(&fakePaymentSvc{recordResult: payment})

	resp := doRequest(t, app, http.MethodPost, "/payments", map[string]any{
		"member_id":       memberID.String(),
		"subscription_id": uuid.NewString(),
		"amount":          1500.00,
		"method":          "Cash",
	})
	require.Equal(t, http.StatusCreated, resp.StatusCode)
	body := decodeBody(t, resp)
	assert.True(t, body["success"].(bool))
	assert.Equal(t, float64(1500), body["data"].(map[string]any)["amount"])
}

func TestRecordPayment_ValidationError(t *testing.T) {
	app := newPaymentTestApp(&fakePaymentSvc{})
	// Invalid method
	resp := doRequest(t, app, http.MethodPost, "/payments", map[string]any{
		"member_id":       uuid.NewString(),
		"subscription_id": uuid.NewString(),
		"amount":          500,
		"method":          "PayPal", // not allowed
	})
	assert.Equal(t, http.StatusBadRequest, resp.StatusCode)
}

func TestRecordPayment_MemberNotFound(t *testing.T) {
	app := newPaymentTestApp(&fakePaymentSvc{recordErr: services.ErrNotFound})
	resp := doRequest(t, app, http.MethodPost, "/payments", map[string]any{
		"member_id":       uuid.NewString(),
		"subscription_id": uuid.NewString(),
		"amount":          500,
		"method":          "bKash",
	})
	assert.Equal(t, http.StatusNotFound, resp.StatusCode)
}

func TestListMemberPayments_NoFilter(t *testing.T) {
	memberID := uuid.New()
	payments := []*models.Payment{samplePayment(memberID), samplePayment(memberID)}
	app := newPaymentTestApp(&fakePaymentSvc{listResult: payments})

	resp := doRequest(t, app, http.MethodGet, "/members/"+memberID.String()+"/payments", nil)
	require.Equal(t, http.StatusOK, resp.StatusCode)
	body := decodeBody(t, resp)
	data := body["data"].([]any)
	assert.Len(t, data, 2)
}

func TestListMemberPayments_WithDateRange(t *testing.T) {
	memberID := uuid.New()
	payments := []*models.Payment{samplePayment(memberID)}
	app := newPaymentTestApp(&fakePaymentSvc{listResult: payments})

	resp := doRequest(t, app, http.MethodGet,
		"/members/"+memberID.String()+"/payments?from=2026-01-01&to=2026-05-31", nil)
	require.Equal(t, http.StatusOK, resp.StatusCode)
	body := decodeBody(t, resp)
	data := body["data"].([]any)
	assert.Len(t, data, 1)
}

func TestListMemberPayments_BadDateFormat(t *testing.T) {
	app := newPaymentTestApp(&fakePaymentSvc{})
	resp := doRequest(t, app, http.MethodGet,
		"/members/"+uuid.NewString()+"/payments?from=16-05-2026", nil) // wrong format
	assert.Equal(t, http.StatusBadRequest, resp.StatusCode)
}

func TestListMemberPayments_MemberNotFound(t *testing.T) {
	app := newPaymentTestApp(&fakePaymentSvc{listErr: services.ErrNotFound})
	resp := doRequest(t, app, http.MethodGet,
		"/members/"+uuid.NewString()+"/payments", nil)
	assert.Equal(t, http.StatusNotFound, resp.StatusCode)
}

func TestGetPaymentSummary_Success(t *testing.T) {
	app := newPaymentTestApp(&fakePaymentSvc{
		summaryResult: &models.PaymentSummary{TotalAmount: 45000, PaymentCount: 30, Month: "2026-05"},
	})
	resp := doRequest(t, app, http.MethodGet, "/payments/summary?month=2026-05", nil)
	require.Equal(t, http.StatusOK, resp.StatusCode)
	body := decodeBody(t, resp)
	data := body["data"].(map[string]any)
	assert.Equal(t, float64(45000), data["total_amount"])
	assert.Equal(t, float64(30), data["payment_count"])
	assert.Equal(t, "2026-05", data["month"])
}

func TestGetPaymentSummary_MissingMonth(t *testing.T) {
	app := newPaymentTestApp(&fakePaymentSvc{})
	resp := doRequest(t, app, http.MethodGet, "/payments/summary", nil) // no ?month
	assert.Equal(t, http.StatusBadRequest, resp.StatusCode)
}

func TestGetPaymentSummary_BadMonthFormat(t *testing.T) {
	app := newPaymentTestApp(&fakePaymentSvc{})
	resp := doRequest(t, app, http.MethodGet, "/payments/summary?month=May-2026", nil)
	assert.Equal(t, http.StatusBadRequest, resp.StatusCode)
}
