package handlers

import (
	"context"
	"fmt"
	"log/slog"
	"time"

	"github.com/asadlive84/fitness-care-bagerhat/internal/models"
	"github.com/asadlive84/fitness-care-bagerhat/internal/services"
	"github.com/asadlive84/fitness-care-bagerhat/internal/utils"
	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
)

// ── Service interfaces (consumer-side, minimal) ───────────────────────────────

type memberProfileSvc interface {
	GetMember(ctx context.Context, id uuid.UUID) (*models.Member, error)
	UpdateMember(ctx context.Context, id uuid.UUID, req services.UpdateMemberRequest) (*models.Member, error)
}

type memberSubSvc interface {
	GetActiveSubscriptionEnriched(ctx context.Context, memberID uuid.UUID) (*models.EnrichedSubscription, error)
}

type memberPaymentSvc interface {
	ListMemberPayments(ctx context.Context, memberID uuid.UUID, filter models.PaymentFilter) ([]*models.Payment, error)
}

type memberWeightSvc interface {
	LogWeight(ctx context.Context, memberID uuid.UUID, weightKg float64, loggedAt time.Time) (*models.WeightLog, error)
	ListWeightLogs(ctx context.Context, memberID uuid.UUID, from, to *time.Time) ([]models.WeightLog, error)
}

type memberWorkoutSvc interface {
	LogWorkout(ctx context.Context, memberID uuid.UUID, content string, loggedAt time.Time) (*models.WorkoutLog, error)
	ListWorkoutLogs(ctx context.Context, memberID uuid.UUID, page, limit int) ([]models.WorkoutLog, error)
}

type memberDietSvc interface {
	LogDiet(ctx context.Context, memberID uuid.UUID, content string, loggedAt time.Time) (*models.DietLog, error)
	ListDietLogs(ctx context.Context, memberID uuid.UUID, page, limit int) ([]models.DietLog, error)
}

// MemberHandler holds all member self-service HTTP handlers.
type MemberHandler struct {
	profile  memberProfileSvc
	subs     memberSubSvc
	payments memberPaymentSvc
	weights  memberWeightSvc
	workouts memberWorkoutSvc
	diets    memberDietSvc
	log      *slog.Logger
}

// NewMemberHandler creates a MemberHandler backed by concrete service types.
func NewMemberHandler(
	profile *services.MemberService,
	subs *services.SubscriptionService,
	payments *services.PaymentService,
	weights *services.WeightLogService,
	workouts *services.WorkoutLogService,
	diets *services.DietLogService,
	log *slog.Logger,
) *MemberHandler {
	return &MemberHandler{
		profile:  profile,
		subs:     subs,
		payments: payments,
		weights:  weights,
		workouts: workouts,
		diets:    diets,
		log:      log,
	}
}

// NewMemberHandlerWithDeps injects interface values — used in tests.
func NewMemberHandlerWithDeps(
	profile memberProfileSvc,
	subs memberSubSvc,
	payments memberPaymentSvc,
	weights memberWeightSvc,
	workouts memberWorkoutSvc,
	diets memberDietSvc,
	log *slog.Logger,
) *MemberHandler {
	return &MemberHandler{profile: profile, subs: subs, payments: payments,
		weights: weights, workouts: workouts, diets: diets, log: log}
}

// memberID extracts the authenticated member's UUID from Fiber locals.
func memberID(c *fiber.Ctx) (uuid.UUID, error) {
	return uuid.Parse(c.Locals("user_id").(string))
}

// ── Profile ───────────────────────────────────────────────────────────────────

// GetProfile godoc
// @Summary     Get member profile
// @Tags        member
// @Security    BearerAuth
// @Produce     json
// @Success     200 {object} map[string]any
// @Router      /api/v1/member/profile [get]
func (h *MemberHandler) GetProfile(c *fiber.Ctx) error {
	id, err := memberID(c)
	if err != nil {
		return utils.ErrorResponse(c, fiber.StatusUnauthorized, "UNAUTHORIZED", "Invalid token", nil)
	}

	member, err := h.profile.GetMember(c.UserContext(), id)
	if err != nil {
		h.log.ErrorContext(c.UserContext(), "get member profile", "error", err)
		return utils.ErrorResponse(c, fiber.StatusInternalServerError, "INTERNAL_ERROR", "Could not fetch profile", nil)
	}

	return utils.SuccessResponse(c, fiber.StatusOK, member)
}

// UpdateProfile godoc
// @Summary     Update member profile (name, goal, current weight)
// @Tags        member
// @Security    BearerAuth
// @Accept      json
// @Produce     json
// @Param       body body updateProfileReq true "Fields to update"
// @Success     200 {object} map[string]any
// @Router      /api/v1/member/profile [patch]
func (h *MemberHandler) UpdateProfile(c *fiber.Ctx) error {
	id, err := memberID(c)
	if err != nil {
		return utils.ErrorResponse(c, fiber.StatusUnauthorized, "UNAUTHORIZED", "Invalid token", nil)
	}

	var req updateProfileReq
	if !parseAndValidate(c, &req) {
		return nil
	}

	// Fetch existing member to preserve phone (member cannot change their own phone).
	existing, err := h.profile.GetMember(c.UserContext(), id)
	if err != nil {
		h.log.ErrorContext(c.UserContext(), "fetch member for profile update", "error", err)
		return utils.ErrorResponse(c, fiber.StatusInternalServerError, "INTERNAL_ERROR", "Could not fetch profile", nil)
	}

	updated, err := h.profile.UpdateMember(c.UserContext(), id, services.UpdateMemberRequest{
		Name:          req.Name,
		Phone:         existing.Phone, // immutable by member
		Goal:          req.Goal,
		CurrentWeight: req.CurrentWeight,
	})
	if err != nil {
		h.log.ErrorContext(c.UserContext(), "update member profile", "error", err)
		return utils.ErrorResponse(c, fiber.StatusInternalServerError, "INTERNAL_ERROR", "Update failed", nil)
	}

	return utils.SuccessResponse(c, fiber.StatusOK, updated)
}

// GetActiveSubscription godoc
// @Summary     Get member's current active subscription
// @Description Returns 200 with the subscription object, or 200 with null data
// @Description when no active subscription exists (never returns 404).
// @Tags        member
// @Security    BearerAuth
// @Produce     json
// @Success     200 {object} map[string]any
// @Router      /api/v1/member/subscription [get]
func (h *MemberHandler) GetActiveSubscription(c *fiber.Ctx) error {
	id, err := memberID(c)
	if err != nil {
		return utils.ErrorResponse(c, fiber.StatusUnauthorized, "UNAUTHORIZED", "Invalid token", nil)
	}

	sub, err := h.subs.GetActiveSubscriptionEnriched(c.UserContext(), id)
	if err != nil {
		h.log.ErrorContext(c.UserContext(), "get active subscription", "error", err)
		return utils.ErrorResponse(c, fiber.StatusInternalServerError, "INTERNAL_ERROR", "Could not fetch subscription", nil)
	}
	// sub == nil means no active subscription — return 200 with null data so
	// the mobile client never crashes on a missing subscription.
	return utils.SuccessResponse(c, fiber.StatusOK, sub)
}

// GetPayments godoc
// @Summary     Get member's own payment history
// @Tags        member
// @Security    BearerAuth
// @Produce     json
// @Param       from query string false "From date (YYYY-MM-DD)"
// @Param       to   query string false "To date (YYYY-MM-DD)"
// @Success     200 {object} map[string]any
// @Router      /api/v1/member/payments [get]
func (h *MemberHandler) GetPayments(c *fiber.Ctx) error {
	id, err := memberID(c)
	if err != nil {
		return utils.ErrorResponse(c, fiber.StatusUnauthorized, "UNAUTHORIZED", "Invalid token", nil)
	}

	filter, err := parseDateRangeFilter(c)
	if err != nil {
		return utils.ErrorResponse(c, fiber.StatusBadRequest, "VALIDATION_ERROR", err.Error(), nil)
	}

	payments, err := h.payments.ListMemberPayments(c.UserContext(), id, filter)
	if err != nil {
		h.log.ErrorContext(c.UserContext(), "get member payments", "error", err)
		return utils.ErrorResponse(c, fiber.StatusInternalServerError, "INTERNAL_ERROR", "Could not fetch payments", nil)
	}

	return utils.SuccessResponse(c, fiber.StatusOK, payments)
}

// ── Weight logs ───────────────────────────────────────────────────────────────

// LogWeight godoc
// @Summary     Log current weight
// @Tags        member/logs
// @Security    BearerAuth
// @Accept      json
// @Produce     json
// @Param       body body logWeightReq true "Weight entry"
// @Success     201 {object} map[string]any
// @Router      /api/v1/member/weight-logs [post]
func (h *MemberHandler) LogWeight(c *fiber.Ctx) error {
	id, err := memberID(c)
	if err != nil {
		return utils.ErrorResponse(c, fiber.StatusUnauthorized, "UNAUTHORIZED", "Invalid token", nil)
	}

	var req logWeightReq
	if !parseAndValidate(c, &req) {
		return nil
	}

	loggedAt := parseOptionalTimestamp(req.LoggedAt)
	entry, err := h.weights.LogWeight(c.UserContext(), id, req.WeightKg, loggedAt)
	if err != nil {
		h.log.ErrorContext(c.UserContext(), "log weight", "error", err)
		return utils.ErrorResponse(c, fiber.StatusInternalServerError, "INTERNAL_ERROR", "Could not save weight log", nil)
	}

	return utils.SuccessResponse(c, fiber.StatusCreated, entry)
}

// ListWeightLogs godoc
// @Summary     List weight logs (optional date range)
// @Tags        member/logs
// @Security    BearerAuth
// @Produce     json
// @Param       from query string false "From date (YYYY-MM-DD)"
// @Param       to   query string false "To date (YYYY-MM-DD)"
// @Success     200 {object} map[string]any
// @Router      /api/v1/member/weight-logs [get]
func (h *MemberHandler) ListWeightLogs(c *fiber.Ctx) error {
	id, err := memberID(c)
	if err != nil {
		return utils.ErrorResponse(c, fiber.StatusUnauthorized, "UNAUTHORIZED", "Invalid token", nil)
	}

	from, to, err := parseDateRange(c)
	if err != nil {
		return utils.ErrorResponse(c, fiber.StatusBadRequest, "VALIDATION_ERROR", err.Error(), nil)
	}

	logs, err := h.weights.ListWeightLogs(c.UserContext(), id, from, to)
	if err != nil {
		h.log.ErrorContext(c.UserContext(), "list weight logs", "error", err)
		return utils.ErrorResponse(c, fiber.StatusInternalServerError, "INTERNAL_ERROR", "Could not fetch weight logs", nil)
	}

	return utils.SuccessResponse(c, fiber.StatusOK, logs)
}

// ── Workout logs ──────────────────────────────────────────────────────────────

// LogWorkout godoc
// @Summary     Log a workout session
// @Tags        member/logs
// @Security    BearerAuth
// @Accept      json
// @Produce     json
// @Param       body body logContentReq true "Workout entry"
// @Success     201 {object} map[string]any
// @Router      /api/v1/member/workout-logs [post]
func (h *MemberHandler) LogWorkout(c *fiber.Ctx) error {
	id, err := memberID(c)
	if err != nil {
		return utils.ErrorResponse(c, fiber.StatusUnauthorized, "UNAUTHORIZED", "Invalid token", nil)
	}

	var req logContentReq
	if !parseAndValidate(c, &req) {
		return nil
	}

	entry, err := h.workouts.LogWorkout(c.UserContext(), id, req.Content, parseOptionalTimestamp(req.LoggedAt))
	if err != nil {
		h.log.ErrorContext(c.UserContext(), "log workout", "error", err)
		return utils.ErrorResponse(c, fiber.StatusInternalServerError, "INTERNAL_ERROR", "Could not save workout log", nil)
	}

	return utils.SuccessResponse(c, fiber.StatusCreated, entry)
}

// ListWorkoutLogs godoc
// @Summary     List workout logs (paginated)
// @Tags        member/logs
// @Security    BearerAuth
// @Produce     json
// @Param       page  query int false "Page (default 1)"
// @Param       limit query int false "Limit (default 20)"
// @Success     200 {object} map[string]any
// @Router      /api/v1/member/workout-logs [get]
func (h *MemberHandler) ListWorkoutLogs(c *fiber.Ctx) error {
	id, err := memberID(c)
	if err != nil {
		return utils.ErrorResponse(c, fiber.StatusUnauthorized, "UNAUTHORIZED", "Invalid token", nil)
	}

	page, limit := parsePagination(c)
	logs, err := h.workouts.ListWorkoutLogs(c.UserContext(), id, page, limit)
	if err != nil {
		h.log.ErrorContext(c.UserContext(), "list workout logs", "error", err)
		return utils.ErrorResponse(c, fiber.StatusInternalServerError, "INTERNAL_ERROR", "Could not fetch workout logs", nil)
	}

	return utils.SuccessResponse(c, fiber.StatusOK, logs)
}

// ── Diet logs ─────────────────────────────────────────────────────────────────

// LogDiet godoc
// @Summary     Log a diet entry
// @Tags        member/logs
// @Security    BearerAuth
// @Accept      json
// @Produce     json
// @Param       body body logContentReq true "Diet entry"
// @Success     201 {object} map[string]any
// @Router      /api/v1/member/diet-logs [post]
func (h *MemberHandler) LogDiet(c *fiber.Ctx) error {
	id, err := memberID(c)
	if err != nil {
		return utils.ErrorResponse(c, fiber.StatusUnauthorized, "UNAUTHORIZED", "Invalid token", nil)
	}

	var req logContentReq
	if !parseAndValidate(c, &req) {
		return nil
	}

	entry, err := h.diets.LogDiet(c.UserContext(), id, req.Content, parseOptionalTimestamp(req.LoggedAt))
	if err != nil {
		h.log.ErrorContext(c.UserContext(), "log diet", "error", err)
		return utils.ErrorResponse(c, fiber.StatusInternalServerError, "INTERNAL_ERROR", "Could not save diet log", nil)
	}

	return utils.SuccessResponse(c, fiber.StatusCreated, entry)
}

// ListDietLogs godoc
// @Summary     List diet logs (paginated)
// @Tags        member/logs
// @Security    BearerAuth
// @Produce     json
// @Param       page  query int false "Page (default 1)"
// @Param       limit query int false "Limit (default 20)"
// @Success     200 {object} map[string]any
// @Router      /api/v1/member/diet-logs [get]
func (h *MemberHandler) ListDietLogs(c *fiber.Ctx) error {
	id, err := memberID(c)
	if err != nil {
		return utils.ErrorResponse(c, fiber.StatusUnauthorized, "UNAUTHORIZED", "Invalid token", nil)
	}

	page, limit := parsePagination(c)
	logs, err := h.diets.ListDietLogs(c.UserContext(), id, page, limit)
	if err != nil {
		h.log.ErrorContext(c.UserContext(), "list diet logs", "error", err)
		return utils.ErrorResponse(c, fiber.StatusInternalServerError, "INTERNAL_ERROR", "Could not fetch diet logs", nil)
	}

	return utils.SuccessResponse(c, fiber.StatusOK, logs)
}

// ── Request DTOs ──────────────────────────────────────────────────────────────

type updateProfileReq struct {
	Name          string   `json:"name"           validate:"required,min=2,max=100"`
	Goal          *string  `json:"goal"`
	CurrentWeight *float64 `json:"current_weight"`
}

type logWeightReq struct {
	WeightKg float64 `json:"weight_kg" validate:"required,gt=0,lte=500"`
	LoggedAt *string `json:"logged_at"` // optional RFC3339
}

type logContentReq struct {
	Content  string  `json:"content"   validate:"required,min=1,max=2000"`
	LoggedAt *string `json:"logged_at"` // optional RFC3339
}

// ── Private helpers ───────────────────────────────────────────────────────────

// parseDateRange parses ?from=YYYY-MM-DD&?to=YYYY-MM-DD query params.
// Both are optional; returns nil pointers when absent.
func parseDateRange(c *fiber.Ctx) (from, to *time.Time, err error) {
	if f := c.Query("from"); f != "" {
		t, e := time.Parse("2006-01-02", f)
		if e != nil {
			return nil, nil, fmt.Errorf("from must be YYYY-MM-DD")
		}
		from = &t
	}
	if t := c.Query("to"); t != "" {
		parsed, e := time.Parse("2006-01-02", t)
		if e != nil {
			return nil, nil, fmt.Errorf("to must be YYYY-MM-DD")
		}
		parsed = parsed.Add(24*time.Hour - time.Second)
		to = &parsed
	}
	return from, to, nil
}

// parseOptionalTimestamp parses an RFC3339 string if non-nil; returns zero time otherwise.
func parseOptionalTimestamp(s *string) time.Time {
	if s == nil {
		return time.Time{}
	}
	t, err := time.Parse(time.RFC3339, *s)
	if err != nil {
		return time.Time{}
	}
	return t
}

