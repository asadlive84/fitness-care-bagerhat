package handlers

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"log/slog"
	"time"

	"github.com/asadlive84/fitness-care-bagerhat/internal/database/sqlc"
	"github.com/asadlive84/fitness-care-bagerhat/internal/models"
	"github.com/asadlive84/fitness-care-bagerhat/internal/repositories/postgres"
	"github.com/asadlive84/fitness-care-bagerhat/internal/services"
	"github.com/asadlive84/fitness-care-bagerhat/internal/utils"
	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
	"github.com/sqlc-dev/pqtype"
)

// adminMemberSvc is the thin service interface the handler depends on.
// Defined in the consumer package per the project's interface convention.
type adminMemberSvc interface {
	CreateMember(ctx context.Context, req services.CreateMemberRequest) (*services.CreateMemberResult, error)
	GetMember(ctx context.Context, id uuid.UUID) (*models.Member, error)
	ListMembers(ctx context.Context, f models.MemberFilter) ([]*models.Member, int64, error)
	ListExpiringSoon(ctx context.Context) ([]*models.Member, error)
	UpdateMember(ctx context.Context, id uuid.UUID, req services.UpdateMemberRequest) (*models.Member, error)
	UpdateMemberStatus(ctx context.Context, id uuid.UUID, status string) error
	ResetMemberPassword(ctx context.Context, id uuid.UUID) (*services.ResetPasswordResult, error)
	DeleteMember(ctx context.Context, id uuid.UUID) error
	InvalidateCache(ctx context.Context, id uuid.UUID, phone string) error
	ApproveMember(ctx context.Context, id uuid.UUID) (*services.ApproveMemberResult, error)
	RejectMember(ctx context.Context, id uuid.UUID) error
}

type adminEnrichedSubSvc interface {
	GetActiveSubscriptionEnriched(ctx context.Context, memberID uuid.UUID) (*models.EnrichedSubscription, error)
}

// memberDetailResp is the enriched response for admin GetMember — embeds all
// member fields and adds the active subscription with plan and payment info.
type memberDetailResp struct {
	*models.Member
	ActiveSubscription *models.EnrichedSubscription `json:"active_subscription"`
}

// AdminMemberHandler holds HTTP handlers for admin member management.
type AdminMemberHandler struct {
	svc    adminMemberSvc
	subs   adminEnrichedSubSvc
	aiRepo *postgres.AIRepo
	aiSvc  *services.AIService
	log    *slog.Logger
}

// NewAdminMemberHandler creates an AdminMemberHandler backed by the concrete services.
func NewAdminMemberHandler(svc *services.MemberService, subs *services.SubscriptionService, aiRepo *postgres.AIRepo, aiSvc *services.AIService, log *slog.Logger) *AdminMemberHandler {
	return &AdminMemberHandler{svc: svc, subs: subs, aiRepo: aiRepo, aiSvc: aiSvc, log: log}
}

// NewAdminMemberHandlerWithSvc creates an AdminMemberHandler with any adminMemberSvc
// implementation — used in tests to inject fakes.
func NewAdminMemberHandlerWithSvc(svc adminMemberSvc, subs adminEnrichedSubSvc, aiRepo *postgres.AIRepo, aiSvc *services.AIService, log *slog.Logger) *AdminMemberHandler {
	return &AdminMemberHandler{svc: svc, subs: subs, aiRepo: aiRepo, aiSvc: aiSvc, log: log}
}

// ── Request DTOs ──────────────────────────────────────────────────────────────

type createMemberReq struct {
	Name             string   `json:"name"              validate:"required,min=2,max=100"`
	Phone            string   `json:"phone"             validate:"required,min=10,max=15"`
	Gender           string   `json:"gender"            validate:"required,oneof=Male Female Other"`
	Goal             *string  `json:"goal"`
	CurrentWeight    *float64 `json:"current_weight"`
	HeightCm         *float64 `json:"height_cm"`
	JoinDate         *string  `json:"join_date"`         // YYYY-MM-DD
	DateOfBirth      *string  `json:"date_of_birth"`    // YYYY-MM-DD
	Religion         *string  `json:"religion"`
	BloodGroup       *string  `json:"blood_group"`
	Hobbies          []string `json:"hobbies"`
	PresentAddress   *string  `json:"present_address"`
	PermanentAddress *string  `json:"permanent_address"`
	Occupation       *string  `json:"occupation"`
	NID              *string  `json:"nid"`
	EmergencyPhone   *string  `json:"emergency_phone"`
	IsAIAllowed        *bool    `json:"is_ai_allowed"`
	IsAIFoodLogAllowed *bool    `json:"is_ai_food_log_allowed"`
}

type updateMemberReq struct {
	Name             string   `json:"name"              validate:"required,min=2,max=100"`
	Phone            string   `json:"phone"             validate:"required,min=10,max=15"`
	Gender           string   `json:"gender"            validate:"required,oneof=Male Female Other"`
	Goal             *string  `json:"goal"`
	CurrentWeight    *float64 `json:"current_weight"`
	HeightCm         *float64 `json:"height_cm"`
	DateOfBirth      *string  `json:"date_of_birth"`    // YYYY-MM-DD
	Religion         *string  `json:"religion"`
	BloodGroup       *string  `json:"blood_group"`
	Hobbies          []string `json:"hobbies"`
	PresentAddress   *string  `json:"present_address"`
	PermanentAddress *string  `json:"permanent_address"`
	Occupation       *string  `json:"occupation"`
	NID              *string  `json:"nid"`
	EmergencyPhone   *string  `json:"emergency_phone"`
}

type updateStatusReq struct {
	Status string `json:"status" validate:"required,oneof=active inactive"`
}

// ── Handlers ──────────────────────────────────────────────────────────────────

// CreateMember godoc
// @Summary     Create a new member
// @Tags        admin/members
// @Security    BearerAuth
// @Accept      json
// @Produce     json
// @Param       body body createMemberReq true "Member details"
// @Success     201 {object} map[string]any
// @Router      /api/v1/admin/members [post]
func (h *AdminMemberHandler) CreateMember(c *fiber.Ctx) error {
	var req createMemberReq
	if !parseAndValidate(c, &req) { // response already written
		return nil
	}

	var createdByAdminID *uuid.UUID
	if adminIDStr, ok := c.Locals("user_id").(string); ok && adminIDStr != "" {
		if parsed, err := uuid.Parse(adminIDStr); err == nil {
			createdByAdminID = &parsed
		}
	}

	svcReq := services.CreateMemberRequest{
		Name:             req.Name,
		Phone:            req.Phone,
		Gender:           req.Gender,
		Goal:             req.Goal,
		CurrentWeight:    req.CurrentWeight,
		HeightCm:         req.HeightCm,
		Religion:         req.Religion,
		BloodGroup:       req.BloodGroup,
		Hobbies:          req.Hobbies,
		PresentAddress:   req.PresentAddress,
		PermanentAddress: req.PermanentAddress,
		Occupation:       req.Occupation,
		NID:              req.NID,
		EmergencyPhone:   req.EmergencyPhone,
		CreatedByAdminID: createdByAdminID,
		IsAIAllowed:        req.IsAIAllowed != nil && *req.IsAIAllowed,
		IsAIFoodLogAllowed: req.IsAIFoodLogAllowed != nil && *req.IsAIFoodLogAllowed,
	}
	if req.JoinDate != nil {
		t, err := parseDate(*req.JoinDate)
		if err != nil {
			return utils.ErrorResponse(c, fiber.StatusBadRequest,
				"VALIDATION_ERROR", "join_date must be YYYY-MM-DD", nil)
		}
		svcReq.JoinDate = t
	}
	if req.DateOfBirth != nil {
		t, err := parseDate(*req.DateOfBirth)
		if err != nil {
			return utils.ErrorResponse(c, fiber.StatusBadRequest,
				"VALIDATION_ERROR", "date_of_birth must be YYYY-MM-DD", nil)
		}
		svcReq.DateOfBirth = &t
	}

	result, err := h.svc.CreateMember(c.UserContext(), svcReq)
	if err != nil {
		if errors.Is(err, services.ErrConflict) {
			return utils.ErrorResponse(c, fiber.StatusConflict,
				"CONFLICT", "Phone number is already registered", nil)
		}
		h.log.ErrorContext(c.UserContext(), "create member", "error", err)
		return utils.ErrorResponse(c, fiber.StatusInternalServerError,
			"INTERNAL_ERROR", "Could not create member", nil)
	}

	return utils.SuccessResponse(c, fiber.StatusCreated, result)
}

// ListMembers godoc
// @Summary     List members (paginated, filterable)
// @Tags        admin/members
// @Security    BearerAuth
// @Produce     json
// @Param       page          query int    false "Page (default 1)"
// @Param       limit         query int    false "Limit (default 20, max 100)"
// @Param       status        query string false "active|inactive"
// @Param       search        query string false "Name or phone search"
// @Param       expiring_soon query bool   false "Only members with expiring subscription"
// @Success     200 {object} map[string]any
// @Router      /api/v1/admin/members [get]
func (h *AdminMemberHandler) ListMembers(c *fiber.Ctx) error {
	page, limit := parsePagination(c)

	if c.QueryBool("expiring_soon", false) {
		members, err := h.svc.ListExpiringSoon(c.UserContext())
		if err != nil {
			h.log.ErrorContext(c.UserContext(), "list expiring members", "error", err)
			return utils.ErrorResponse(c, fiber.StatusInternalServerError,
				"INTERNAL_ERROR", "Could not fetch expiring members", nil)
		}
		var enrichedMembers []memberDetailResp
		for _, m := range members {
			activeSub, _ := h.subs.GetActiveSubscriptionEnriched(c.UserContext(), m.ID)
			enrichedMembers = append(enrichedMembers, memberDetailResp{
				Member:             m,
				ActiveSubscription: activeSub,
			})
		}
		return utils.PaginatedResponse(c, enrichedMembers, 1, len(enrichedMembers), len(enrichedMembers))
	}

	var status *string
	if s := c.Query("status"); s != "" {
		status = &s
	}
	var search *string
	if s := c.Query("search"); s != "" {
		search = &s
	}

	members, total, err := h.svc.ListMembers(c.UserContext(), models.MemberFilter{
		Status: status,
		Search: search,
		Page:   page,
		Limit:  limit,
	})
	if err != nil {
		h.log.ErrorContext(c.UserContext(), "list members", "error", err)
		return utils.ErrorResponse(c, fiber.StatusInternalServerError,
			"INTERNAL_ERROR", "Could not fetch members", nil)
	}

	var enrichedMembers []memberDetailResp
	for _, m := range members {
		activeSub, _ := h.subs.GetActiveSubscriptionEnriched(c.UserContext(), m.ID)
		enrichedMembers = append(enrichedMembers, memberDetailResp{
			Member:             m,
			ActiveSubscription: activeSub,
		})
	}

	return utils.PaginatedResponse(c, enrichedMembers, page, limit, int(total))
}

// GetMember godoc
// @Summary     Get a member by ID
// @Tags        admin/members
// @Security    BearerAuth
// @Produce     json
// @Param       id path string true "Member UUID"
// @Success     200 {object} map[string]any
// @Failure     404 {object} map[string]any
// @Router      /api/v1/admin/members/{id} [get]
func (h *AdminMemberHandler) GetMember(c *fiber.Ctx) error {
	id, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return utils.ErrorResponse(c, fiber.StatusBadRequest,
			"INVALID_ID", "Member ID must be a valid UUID", nil)
	}

	member, err := h.svc.GetMember(c.UserContext(), id)
	if err != nil {
		if errors.Is(err, services.ErrNotFound) {
			return utils.ErrorResponse(c, fiber.StatusNotFound,
				"NOT_FOUND", "Member not found", nil)
		}
		h.log.ErrorContext(c.UserContext(), "get member", "error", err)
		return utils.ErrorResponse(c, fiber.StatusInternalServerError,
			"INTERNAL_ERROR", "Could not fetch member", nil)
	}

	// Enrich with active subscription (plan info + payment totals). Errors are
	// non-fatal — we still return the member profile if the query fails.
	activeSub, _ := h.subs.GetActiveSubscriptionEnriched(c.UserContext(), id)

	return utils.SuccessResponse(c, fiber.StatusOK, memberDetailResp{
		Member:             member,
		ActiveSubscription: activeSub,
	})
}

// UpdateMember godoc
// @Summary     Update member profile
// @Tags        admin/members
// @Security    BearerAuth
// @Accept      json
// @Produce     json
// @Param       id   path string         true "Member UUID"
// @Param       body body updateMemberReq true "Updated fields"
// @Success     200 {object} map[string]any
// @Router      /api/v1/admin/members/{id} [patch]
func (h *AdminMemberHandler) UpdateMember(c *fiber.Ctx) error {
	id, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return utils.ErrorResponse(c, fiber.StatusBadRequest,
			"INVALID_ID", "Member ID must be a valid UUID", nil)
	}

	var req updateMemberReq
	if !parseAndValidate(c, &req) { // response already written
		return nil
	}

	svcUpd := services.UpdateMemberRequest{
		Name:             req.Name,
		Phone:            req.Phone,
		Gender:           req.Gender,
		Goal:             req.Goal,
		CurrentWeight:    req.CurrentWeight,
		HeightCm:         req.HeightCm,
		Religion:         req.Religion,
		BloodGroup:       req.BloodGroup,
		Hobbies:          req.Hobbies,
		PresentAddress:   req.PresentAddress,
		PermanentAddress: req.PermanentAddress,
		Occupation:       req.Occupation,
		NID:              req.NID,
		EmergencyPhone:   req.EmergencyPhone,
	}
	if req.DateOfBirth != nil {
		t, err := parseDate(*req.DateOfBirth)
		if err != nil {
			return utils.ErrorResponse(c, fiber.StatusBadRequest,
				"VALIDATION_ERROR", "date_of_birth must be YYYY-MM-DD", nil)
		}
		svcUpd.DateOfBirth = &t
	}
	member, err := h.svc.UpdateMember(c.UserContext(), id, svcUpd)
	if err != nil {
		switch {
		case errors.Is(err, services.ErrNotFound):
			return utils.ErrorResponse(c, fiber.StatusNotFound, "NOT_FOUND", "Member not found", nil)
		case errors.Is(err, services.ErrConflict):
			return utils.ErrorResponse(c, fiber.StatusConflict, "CONFLICT", "Phone already registered", nil)
		default:
			h.log.ErrorContext(c.UserContext(), "update member", "error", err)
			return utils.ErrorResponse(c, fiber.StatusInternalServerError, "INTERNAL_ERROR", "Update failed", nil)
		}
	}

	return utils.SuccessResponse(c, fiber.StatusOK, member)
}

// UpdateMemberStatus godoc
// @Summary     Set member active/inactive
// @Tags        admin/members
// @Security    BearerAuth
// @Accept      json
// @Produce     json
// @Param       id   path string         true "Member UUID"
// @Param       body body updateStatusReq true "New status"
// @Success     204
// @Router      /api/v1/admin/members/{id}/status [patch]
func (h *AdminMemberHandler) UpdateMemberStatus(c *fiber.Ctx) error {
	id, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return utils.ErrorResponse(c, fiber.StatusBadRequest,
			"INVALID_ID", "Member ID must be a valid UUID", nil)
	}

	var req updateStatusReq
	if !parseAndValidate(c, &req) { // response already written
		return nil
	}

	if err := h.svc.UpdateMemberStatus(c.UserContext(), id, req.Status); err != nil {
		if errors.Is(err, services.ErrNotFound) {
			return utils.ErrorResponse(c, fiber.StatusNotFound, "NOT_FOUND", "Member not found", nil)
		}
		h.log.ErrorContext(c.UserContext(), "update member status", "error", err)
		return utils.ErrorResponse(c, fiber.StatusInternalServerError, "INTERNAL_ERROR", "Status update failed", nil)
	}

	return c.SendStatus(fiber.StatusNoContent)
}

// ResetMemberPassword godoc
// @Summary     Reset a member's password (admin)
// @Description Generates a new temporary password for the member. The member
// @Description must change it on next login. Returns the plaintext temp password
// @Description so the admin can share it with the member.
// @Tags        admin/members
// @Security    BearerAuth
// @Produce     json
// @Param       id path string true "Member UUID"
// @Success     200 {object} map[string]any
// @Failure     404 {object} map[string]any
// @Router      /api/v1/admin/members/{id}/password/reset [post]
func (h *AdminMemberHandler) ResetMemberPassword(c *fiber.Ctx) error {
	id, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return utils.ErrorResponse(c, fiber.StatusBadRequest,
			"INVALID_ID", "Member ID must be a valid UUID", nil)
	}

	result, err := h.svc.ResetMemberPassword(c.UserContext(), id)
	if err != nil {
		if errors.Is(err, services.ErrNotFound) {
			return utils.ErrorResponse(c, fiber.StatusNotFound, "NOT_FOUND", "Member not found", nil)
		}
		h.log.ErrorContext(c.UserContext(), "reset member password", "error", err)
		return utils.ErrorResponse(c, fiber.StatusInternalServerError, "INTERNAL_ERROR", "Password reset failed", nil)
	}

	return utils.SuccessResponse(c, fiber.StatusOK, result)
}

// DeleteMember godoc
// @Summary     Permanently delete a member and all their data
// @Description Removes the member plus all related records (subscriptions, payments,
// @Description logs, messages, notifications, FCM tokens) in a single transaction.
// @Tags        admin/members
// @Security    BearerAuth
// @Produce     json
// @Param       id path string true "Member UUID"
// @Success     204
// @Failure     404 {object} map[string]any
// @Router      /api/v1/admin/members/{id} [delete]
func (h *AdminMemberHandler) DeleteMember(c *fiber.Ctx) error {
	id, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return utils.ErrorResponse(c, fiber.StatusBadRequest,
			"INVALID_ID", "Member ID must be a valid UUID", nil)
	}

	if err := h.svc.DeleteMember(c.UserContext(), id); err != nil {
		if errors.Is(err, services.ErrNotFound) {
			return utils.ErrorResponse(c, fiber.StatusNotFound, "NOT_FOUND", "Member not found", nil)
		}
		h.log.ErrorContext(c.UserContext(), "delete member", "error", err)
		return utils.ErrorResponse(c, fiber.StatusInternalServerError, "INTERNAL_ERROR", "Delete failed", nil)
	}

	return c.SendStatus(fiber.StatusNoContent)
}

// ApproveMember activates a pending self-registered member and returns a temp password.
func (h *AdminMemberHandler) ApproveMember(c *fiber.Ctx) error {
	id, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return utils.ErrorResponse(c, fiber.StatusBadRequest, "INVALID_ID", "Member ID must be a valid UUID", nil)
	}

	result, err := h.svc.ApproveMember(c.UserContext(), id)
	if err != nil {
		switch {
		case errors.Is(err, services.ErrNotFound):
			return utils.ErrorResponse(c, fiber.StatusNotFound, "NOT_FOUND", "Member not found", nil)
		case errors.Is(err, services.ErrConflict):
			return utils.ErrorResponse(c, fiber.StatusConflict, "CONFLICT", "Member is not in pending state", nil)
		default:
			h.log.ErrorContext(c.UserContext(), "approve member", "error", err)
			return utils.ErrorResponse(c, fiber.StatusInternalServerError, "INTERNAL_ERROR", "Approval failed", nil)
		}
	}

	return utils.SuccessResponse(c, fiber.StatusOK, result)
}

// RejectMember marks a pending self-registered member as rejected.
func (h *AdminMemberHandler) RejectMember(c *fiber.Ctx) error {
	id, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return utils.ErrorResponse(c, fiber.StatusBadRequest, "INVALID_ID", "Member ID must be a valid UUID", nil)
	}

	if err := h.svc.RejectMember(c.UserContext(), id); err != nil {
		switch {
		case errors.Is(err, services.ErrNotFound):
			return utils.ErrorResponse(c, fiber.StatusNotFound, "NOT_FOUND", "Member not found", nil)
		case errors.Is(err, services.ErrConflict):
			return utils.ErrorResponse(c, fiber.StatusConflict, "CONFLICT", "Member is not in pending state", nil)
		default:
			h.log.ErrorContext(c.UserContext(), "reject member", "error", err)
			return utils.ErrorResponse(c, fiber.StatusInternalServerError, "INTERNAL_ERROR", "Rejection failed", nil)
		}
	}

	return c.SendStatus(fiber.StatusNoContent)
}

// ── shared helpers ────────────────────────────────────────────────────────────

func parsePagination(c *fiber.Ctx) (page, limit int) {
	page = c.QueryInt("page", 1)
	limit = c.QueryInt("limit", 20)
	if page < 1 {
		page = 1
	}
	if limit < 1 || limit > 100 {
		limit = 20
	}
	return
}

// UpdateMemberProfilePicture godoc
// @Summary     Update member profile picture (admin)
// @Tags        admin/members
// @Security    BearerAuth
// @Accept      json
// @Produce     json
// @Param       id path string true "Member ID"
// @Param       body body map[string]string true "Request body (profile_picture_url)"
// @Success     200 {object} map[string]any
// @Router      /api/v1/admin/members/{id}/profile-picture [patch]
func (h *AdminMemberHandler) UpdateMemberProfilePicture(c *fiber.Ctx) error {
	ctx := c.UserContext()
	id, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return utils.ErrorResponse(c, fiber.StatusBadRequest, "INVALID_ID", "Invalid member ID format", nil)
	}

	admin, _ := c.Locals("admin_obj").(*models.Admin)
	if admin == nil {
		return utils.ErrorResponse(c, fiber.StatusUnauthorized, "UNAUTHORIZED", "Unauthorized", nil)
	}

	var req struct {
		ProfilePictureURL string `json:"profile_picture_url"`
	}

	if err := c.BodyParser(&req); err != nil {
		return utils.ErrorResponse(c, fiber.StatusBadRequest, "BAD_REQUEST", "Invalid request body", nil)
	}

	if req.ProfilePictureURL == "" {
		return utils.ErrorResponse(c, fiber.StatusBadRequest, "BAD_REQUEST", "Profile picture URL cannot be empty", nil)
	}

	// Fetch member to ensure they exist and get current profile picture
	member, err := h.svc.GetMember(ctx, id)
	if err != nil {
		if errors.Is(err, services.ErrNotFound) {
			return utils.ErrorResponse(c, fiber.StatusNotFound, "NOT_FOUND", "Member not found", nil)
		}
		h.log.Error("Failed to fetch member", "error", err, "id", id)
		return utils.ErrorResponse(c, fiber.StatusInternalServerError, "INTERNAL_ERROR", "Failed to fetch member", nil)
	}

	if member.ProfilePictureURL != nil && *member.ProfilePictureURL == req.ProfilePictureURL {
		return utils.SuccessResponse(c, fiber.StatusOK, nil) // no change
	}

	// Enforce 3 update limit for admin updates
	count, err := h.aiRepo.CountProfilePictureUpdates(ctx, sqlcdb.CountProfilePictureUpdatesParams{
		MemberID:      member.ID,
		UpdatedByRole: "admin",
	})
	if err != nil {
		h.log.Error("Failed to count profile picture updates", "member_id", member.ID, "error", err)
		return utils.ErrorResponse(c, fiber.StatusInternalServerError, "INTERNAL_ERROR", "Failed to verify update limits", nil)
	}

	if count >= 3 {
		return utils.ErrorResponse(c, fiber.StatusForbidden, "LIMIT_REACHED", "You have reached the maximum allowed profile picture updates (3) for this member.", nil)
	}

	budgetLevel := sql.NullString{}
	if member.BudgetLevel != nil {
		budgetLevel = sql.NullString{String: *member.BudgetLevel, Valid: true}
	}

	// Update the profile picture
	_, err = h.aiRepo.UpdateMemberAIProfile(ctx, sqlcdb.UpdateMemberAIProfileParams{
		ID:                member.ID,
		IsAiAllowed:       member.IsAIAllowed,
		BudgetLevel:       budgetLevel,
		ProfilePictureUrl: sql.NullString{String: req.ProfilePictureURL, Valid: true},
	})
	if err != nil {
		h.log.Error("Failed to update AI profile picture", "member_id", member.ID, "error", err)
		return utils.ErrorResponse(c, fiber.StatusInternalServerError, "INTERNAL_ERROR", "Failed to update profile picture", nil)
	}

	// Record the update
	_, err = h.aiRepo.RecordProfilePictureUpdate(ctx, sqlcdb.RecordProfilePictureUpdateParams{
		MemberID:      member.ID,
		UpdatedByRole: "admin",
		UpdatedByID:   admin.ID,
	})
	if err != nil {
		h.log.Error("Failed to record profile picture update", "member_id", member.ID, "error", err)
		// We still return success as the picture was updated, but we log the error
	}

	return utils.SuccessResponse(c, fiber.StatusOK, fiber.Map{
		"message": "Profile picture updated successfully",
	})
}

func parseDate(s string) (time.Time, error) {
	return time.Parse("2006-01-02", s)
}

// UpdateMemberAI godoc
// @Summary     Update member AI settings
// @Tags        admin/members
// @Security    BearerAuth
// @Accept      json
// @Produce     json
// @Param       id path string true "Member ID"
// @Param       body body map[string]any true "Request body (is_ai_allowed, budget_level)"
// @Success     200 {object} map[string]any
// @Router      /api/v1/admin/members/{id}/ai [patch]
func (h *AdminMemberHandler) UpdateMemberAI(c *fiber.Ctx) error {
	role, _ := c.Locals("role").(string)
	if role != "superadmin" {
		return utils.ErrorResponse(c, fiber.StatusForbidden, "FORBIDDEN", "Only Superadmins can modify member AI feature permissions", nil)
	}

	ctx := c.UserContext()
	id, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return utils.ErrorResponse(c, fiber.StatusBadRequest, "INVALID_ID", "Member ID must be a valid UUID", nil)
	}

	var req struct {
		IsAiAllowed        *bool   `json:"is_ai_allowed" validate:"required"`
		IsAiFoodLogAllowed *bool   `json:"is_ai_food_log_allowed"`
		BudgetLevel        *string `json:"budget_level"`
	}
	if err := c.BodyParser(&req); err != nil {
		return utils.ErrorResponse(c, fiber.StatusBadRequest, "BAD_REQUEST", "Invalid request body", nil)
	}
	if req.IsAiAllowed == nil {
		return utils.ErrorResponse(c, fiber.StatusBadRequest, "VALIDATION_ERROR", "is_ai_allowed is required", nil)
	}

	member, err := h.svc.GetMember(ctx, id)
	if err != nil {
		if errors.Is(err, services.ErrNotFound) {
			return utils.ErrorResponse(c, fiber.StatusNotFound, "NOT_FOUND", "Member not found", nil)
		}
		h.log.ErrorContext(ctx, "update member ai: get member", "error", err)
		return utils.ErrorResponse(c, fiber.StatusInternalServerError, "INTERNAL_ERROR", "Failed to fetch member", nil)
	}

	isAiFoodLogAllowed := member.IsAIFoodLogAllowed
	if req.IsAiFoodLogAllowed != nil {
		isAiFoodLogAllowed = *req.IsAiFoodLogAllowed
	}

	budgetLevel := sql.NullString{}
	if req.BudgetLevel != nil {
		budgetLevel = sql.NullString{String: *req.BudgetLevel, Valid: true}
	} else if member.BudgetLevel != nil {
		budgetLevel = sql.NullString{String: *member.BudgetLevel, Valid: true}
	}

	profilePic := sql.NullString{}
	if member.ProfilePictureURL != nil {
		profilePic = sql.NullString{String: *member.ProfilePictureURL, Valid: true}
	}

	_, err = h.aiRepo.UpdateMemberAIProfile(ctx, sqlcdb.UpdateMemberAIProfileParams{
		ID:                 member.ID,
		BudgetLevel:        budgetLevel,
		IsAiAllowed:        *req.IsAiAllowed,
		IsAiFoodLogAllowed: isAiFoodLogAllowed,
		ProfilePictureUrl:  profilePic,
	})
	if err != nil {
		h.log.ErrorContext(ctx, "update member ai profile", "error", err)
		return utils.ErrorResponse(c, fiber.StatusInternalServerError, "INTERNAL_ERROR", "Failed to update AI profile", nil)
	}

	// Invalidate cache
	_ = h.svc.InvalidateCache(ctx, member.ID, member.Phone)

	// Fetch fresh member
	freshMember, err := h.svc.GetMember(ctx, id)
	if err != nil {
		return utils.ErrorResponse(c, fiber.StatusInternalServerError, "INTERNAL_ERROR", "Failed to fetch updated member", nil)
	}

	return utils.SuccessResponse(c, fiber.StatusOK, freshMember)
}

// GenerateMemberDietChart godoc
// @Summary     Generate AI diet chart for a member
// @Tags        admin/members
// @Security    BearerAuth
// @Produce     json
// @Param       id path string true "Member ID"
// @Success     200 {object} map[string]any
// @Router      /api/v1/admin/members/{id}/diet-chart [post]
func (h *AdminMemberHandler) GenerateMemberDietChart(c *fiber.Ctx) error {
	ctx := c.UserContext()
	id, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return utils.ErrorResponse(c, fiber.StatusBadRequest, "INVALID_ID", "Member ID must be a valid UUID", nil)
	}

	// Fetch member
	member, err := h.svc.GetMember(ctx, id)
	if err != nil {
		if errors.Is(err, services.ErrNotFound) {
			return utils.ErrorResponse(c, fiber.StatusNotFound, "NOT_FOUND", "Member not found", nil)
		}
		h.log.ErrorContext(ctx, "generate member diet chart: get member", "error", err)
		return utils.ErrorResponse(c, fiber.StatusInternalServerError, "INTERNAL_ERROR", "Failed to fetch member", nil)
	}

	// Check if the member has AI allowed. (Admin can trigger this, but let's check or override if needed. It's safe to just proceed or make sure budget level is set)
	role, _ := c.Locals("role").(string)
	if role != "superadmin" {
		count, err := h.aiRepo.CountDietChartsGenerated(ctx, member.ID)
		if err != nil {
			h.log.ErrorContext(ctx, "failed to count diet charts", "error", err, "member_id", member.ID)
			return utils.ErrorResponse(c, fiber.StatusInternalServerError, "INTERNAL_ERROR", "Failed to check diet generation limit", nil)
		}
		if count >= 3 {
			return utils.ErrorResponse(c, fiber.StatusForbidden, "RATE_LIMIT_EXCEEDED", "Admins can generate at most 3 diet charts per member. Please contact a Superadmin to bypass this limit.", nil)
		}
	}

	// Parse optional body fields (gym_time, location, max_budget_bdt, language)
	type generateDietChartRequest struct {
		Language     string `json:"language"`
		GymTime      string `json:"gym_time"`
		Location     string `json:"location"`
		MaxBudgetBDT string `json:"max_budget_bdt"`
	}
	var req generateDietChartRequest
	_ = c.BodyParser(&req)
	// language can also come from query param for backward compat
	if req.Language == "" {
		req.Language = c.Query("language", "bn")
	}
	if req.Language != "bn" {
		req.Language = "en"
	}

	if member.BudgetLevel == nil || *member.BudgetLevel == "" {
		defaultBudget := "Low"
		member.BudgetLevel = &defaultBudget
	}

	fmt.Printf("Generating diet chart for member %s (ID: %s) gym_time=%q location=%q budget=%q lang=%s\n",
		member.Name, member.ID, req.GymTime, req.Location, req.MaxBudgetBDT, req.Language)

	opts := services.DietChartOptions{
		Language:     req.Language,
		GymTime:      req.GymTime,
		Location:     req.Location,
		MaxBudgetBDT: req.MaxBudgetBDT,
	}

	dietJSON, tokens, err := h.aiSvc.GenerateDietChart(ctx, member, opts)
	if err != nil {
		h.log.ErrorContext(ctx, "generate diet chart failed", "error", err, "member_id", member.ID)
		return utils.ErrorResponse(c, fiber.StatusInternalServerError, "INTERNAL_ERROR", "Failed to generate diet chart", nil)
	}

	// Persist the generated diet chart to the member's profile as a pending chart awaiting admin review
	_, err = h.aiRepo.UpdateMemberPendingDietChart(ctx, sqlcdb.UpdateMemberPendingDietChartParams{
		ID: member.ID,
		PendingDietChartJson: pqtype.NullRawMessage{
			RawMessage: dietJSON,
			Valid:      true,
		},
	})
	if err != nil {
		h.log.ErrorContext(ctx, "failed to persist generated diet chart", "error", err, "member_id", member.ID)
		return utils.ErrorResponse(c, fiber.StatusInternalServerError, "INTERNAL_ERROR", "Failed to persist diet chart", nil)
	}

	// Invalidate the cache
	_ = h.svc.InvalidateCache(ctx, member.ID, member.Phone)

	// Log tokens
	_, _ = h.aiRepo.LogAITokenUsage(ctx, sqlcdb.LogAITokenUsageParams{
		MemberID:         member.ID,
		FeatureUsed:      "diet_chart",
		PromptTokens:     0,
		CompletionTokens: 0,
		TotalTokens:      int32(tokens),
	})

	if member.CreatedByAdminID != nil {
		cost := float64(tokens) * 0.000002 // estimate $0.002 per 1K tokens
		_, _ = h.aiRepo.LogAIAuditUsage(ctx, sqlcdb.LogAIAuditUsageParams{
			MemberID:         member.ID,
			AdminID:          *member.CreatedByAdminID,
			PromptType:       "diet_chart",
			PromptText:       "Admin-initiated personalized diet generation request",
			AiResponseJson:   dietJSON,
			PromptTokens:     0,
			CompletionTokens: 0,
			TotalTokens:      int32(tokens),
			EstimatedCost:    cost,
		})
	}

	return utils.SuccessResponse(c, fiber.StatusOK, dietJSON)
}

// ApproveMemberDietChart godoc
// @Summary     Approve pending AI diet chart for a member
// @Tags        admin/members
// @Security    BearerAuth
// @Produce     json
// @Param       id path string true "Member ID"
// @Success     200 {object} map[string]any
// @Router      /api/v1/admin/members/{id}/diet-chart/approve [post]
func (h *AdminMemberHandler) ApproveMemberDietChart(c *fiber.Ctx) error {
	ctx := c.UserContext()
	id, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return utils.ErrorResponse(c, fiber.StatusBadRequest, "INVALID_ID", "Member ID must be a valid UUID", nil)
	}

	member, err := h.svc.GetMember(ctx, id)
	if err != nil {
		if errors.Is(err, services.ErrNotFound) {
			return utils.ErrorResponse(c, fiber.StatusNotFound, "NOT_FOUND", "Member not found", nil)
		}
		h.log.ErrorContext(ctx, "approve member diet chart: get member", "error", err)
		return utils.ErrorResponse(c, fiber.StatusInternalServerError, "INTERNAL_ERROR", "Failed to fetch member", nil)
	}

	_, err = h.aiRepo.ApprovePendingDietChart(ctx, member.ID)
	if err != nil {
		h.log.ErrorContext(ctx, "approve pending diet chart failed", "error", err, "member_id", member.ID)
		return utils.ErrorResponse(c, fiber.StatusInternalServerError, "INTERNAL_ERROR", "Failed to approve diet chart", nil)
	}

	_ = h.svc.InvalidateCache(ctx, member.ID, member.Phone)

	freshMember, err := h.svc.GetMember(ctx, id)
	if err != nil {
		return utils.ErrorResponse(c, fiber.StatusInternalServerError, "INTERNAL_ERROR", "Failed to fetch updated member", nil)
	}

	return utils.SuccessResponse(c, fiber.StatusOK, freshMember)
}

// DeclineMemberDietChart godoc
// @Summary     Decline/discard pending AI diet chart for a member
// @Tags        admin/members
// @Security    BearerAuth
// @Produce     json
// @Param       id path string true "Member ID"
// @Success     200 {object} map[string]any
// @Router      /api/v1/admin/members/{id}/diet-chart/decline [post]
func (h *AdminMemberHandler) DeclineMemberDietChart(c *fiber.Ctx) error {
	ctx := c.UserContext()
	id, err := uuid.Parse(c.Params("id"))
	if err != nil {
		return utils.ErrorResponse(c, fiber.StatusBadRequest, "INVALID_ID", "Member ID must be a valid UUID", nil)
	}

	member, err := h.svc.GetMember(ctx, id)
	if err != nil {
		if errors.Is(err, services.ErrNotFound) {
			return utils.ErrorResponse(c, fiber.StatusNotFound, "NOT_FOUND", "Member not found", nil)
		}
		h.log.ErrorContext(ctx, "decline member diet chart: get member", "error", err)
		return utils.ErrorResponse(c, fiber.StatusInternalServerError, "INTERNAL_ERROR", "Failed to fetch member", nil)
	}

	_, err = h.aiRepo.DeclinePendingDietChart(ctx, member.ID)
	if err != nil {
		h.log.ErrorContext(ctx, "decline pending diet chart failed", "error", err, "member_id", member.ID)
		return utils.ErrorResponse(c, fiber.StatusInternalServerError, "INTERNAL_ERROR", "Failed to decline diet chart", nil)
	}

	_ = h.svc.InvalidateCache(ctx, member.ID, member.Phone)

	freshMember, err := h.svc.GetMember(ctx, id)
	if err != nil {
		return utils.ErrorResponse(c, fiber.StatusInternalServerError, "INTERNAL_ERROR", "Failed to fetch updated member", nil)
	}

	return utils.SuccessResponse(c, fiber.StatusOK, freshMember)
}

