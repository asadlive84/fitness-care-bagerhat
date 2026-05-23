package handlers

import (
	"database/sql"
	"fmt"
	"log/slog"
	"os"
	"path/filepath"
	"strings"

	"github.com/asadlive84/fitness-care-bagerhat/internal/database/sqlc"
	"github.com/asadlive84/fitness-care-bagerhat/internal/models"
	"github.com/asadlive84/fitness-care-bagerhat/internal/repositories"
	"github.com/asadlive84/fitness-care-bagerhat/internal/repositories/postgres"
	"github.com/asadlive84/fitness-care-bagerhat/internal/services"
	"github.com/asadlive84/fitness-care-bagerhat/internal/utils"
	"github.com/gofiber/fiber/v2"
	"github.com/sqlc-dev/pqtype"
)

type AIHandler struct {
	aiSvc      *services.AIService
	aiRepo     *postgres.AIRepo
	memberRepo repositories.MemberRepository
	log        *slog.Logger
}

func NewAIHandler(aiSvc *services.AIService, aiRepo *postgres.AIRepo, memberRepo repositories.MemberRepository, log *slog.Logger) *AIHandler {
	return &AIHandler{
		aiSvc:      aiSvc,
		aiRepo:     aiRepo,
		memberRepo: memberRepo,
		log:        log.With(slog.String("component", "ai_handler")),
	}
}

// GenerateDietChart
//	@Summary		Generate AI Diet Chart
//	@Description	Generate a personalized diet chart using DeepSeek.
//	@Tags			AI
//	@Produce		json
//	@Security		BearerAuth
//	@Success		200		{object}	response.Response
//	@Failure		500		{object}	response.Response
//	@Router			/api/v1/ai/diet-chart [post]
func (h *AIHandler) GenerateDietChart(c *fiber.Ctx) error {
	fmt.Print("Generating diet chart...")
	return utils.ErrorResponse(c, fiber.StatusForbidden, "FORBIDDEN", "Members are not allowed to generate diet charts. Please contact your trainer/admin.", nil)
}

// AnalyzeFoodImage
//	@Summary		Analyze Food Image
//	@Description	Analyze an uploaded food image using Gemini Vision.
//	@Tags			AI
//	@Accept			json
//	@Produce		json
//	@Security		BearerAuth
//	@Param			request	body		map[string]string	true	"Request body (image_url)"
//	@Success		200		{object}	response.Response
//	@Failure		400		{object}	response.Response
//	@Failure		500		{object}	response.Response
//	@Router			/api/v1/ai/food-log [post]
func (h *AIHandler) AnalyzeFoodImage(c *fiber.Ctx) error {
	ctx := c.UserContext()
	member, _ := c.Locals("member_obj").(*models.Member)

	var req struct {
		ImageURL string `json:"image_url"`
	}
	if err := c.BodyParser(&req); err != nil {
		return utils.ErrorResponse(c, fiber.StatusBadRequest, "BAD_REQUEST", "Invalid request", nil)
	}

	if req.ImageURL == "" || !strings.HasPrefix(req.ImageURL, "/uploads/") {
		return utils.ErrorResponse(c, fiber.StatusBadRequest, "BAD_REQUEST", "Invalid image URL", nil)
	}

	// Determine file path
	baseDir := "./uploads" // Ideally from config
	fileName := strings.TrimPrefix(req.ImageURL, "/uploads/")
	filePath := filepath.Join(baseDir, fileName)

	// Read image bytes
	imageBytes, err := os.ReadFile(filePath)
	if err != nil {
		h.log.Error("Failed to read image file", "path", filePath, "error", err)
		return utils.ErrorResponse(c, fiber.StatusInternalServerError, "INTERNAL_ERROR", "Failed to read image file", nil)
	}

	mimeType := "image/jpeg"
	if strings.HasSuffix(strings.ToLower(fileName), ".png") {
		mimeType = "image/png"
	} else if strings.HasSuffix(strings.ToLower(fileName), ".webp") {
		mimeType = "image/webp"
	}

	nutritionJSON, tokens, err := h.aiSvc.GenerateNutritionFromImage(ctx, member, imageBytes, mimeType)
	if err != nil {
		return utils.ErrorResponse(c, fiber.StatusInternalServerError, "INTERNAL_ERROR", "Failed to analyze food image", nil)
	}

	// Log tokens
	_, _ = h.aiRepo.LogAITokenUsage(ctx, sqlcdb.LogAITokenUsageParams{
		MemberID:         member.ID,
		FeatureUsed:      "food_log",
		TotalTokens:      int32(tokens),
	})

	if member.CreatedByAdminID != nil {
		cost := float64(tokens) * 0.000002 // estimate $0.002 per 1K tokens
		_, _ = h.aiRepo.LogAIAuditUsage(ctx, sqlcdb.LogAIAuditUsageParams{
			MemberID:         member.ID,
			AdminID:          *member.CreatedByAdminID,
			PromptType:       "food_log",
			PromptText:       "AI Food Log image analysis request",
			AiResponseJson:   nutritionJSON,
			PromptTokens:     0,
			CompletionTokens: 0,
			TotalTokens:      int32(tokens),
			EstimatedCost:    cost,
		})
	}

	// Save to member_food_logs
	_, _ = h.aiRepo.CreateMemberFoodLog(ctx, sqlcdb.CreateMemberFoodLogParams{
		MemberID: member.ID,
		ImageUrl: req.ImageURL,
		AiResponseJson: pqtype.NullRawMessage{
			RawMessage: nutritionJSON,
			Valid:      true,
		},
	})

	return utils.SuccessResponse(c, fiber.StatusOK, nutritionJSON)
}

// SetupAIProfile
//	@Summary		Setup AI Profile
//	@Description	Updates the member's budget level and profile picture URL.
//	@Tags			AI
//	@Accept			json
//	@Produce		json
//	@Security		BearerAuth
//	@Param			request	body		map[string]string	true	"Request body (budget_level, profile_picture_url)"
//	@Success		200		{object}	response.Response
//	@Failure		400		{object}	response.Response
//	@Failure		500		{object}	response.Response
//	@Router			/api/v1/ai/profile [patch]
func (h *AIHandler) SetupAIProfile(c *fiber.Ctx) error {
	ctx := c.UserContext()
	member, _ := c.Locals("member_obj").(*models.Member)

	var req struct {
		BudgetLevel       string `json:"budget_level"`
		ProfilePictureURL string `json:"profile_picture_url"`
	}

	if err := c.BodyParser(&req); err != nil {
		return utils.ErrorResponse(c, fiber.StatusBadRequest, "BAD_REQUEST", "Invalid request", nil)
	}

	arg := sqlcdb.UpdateMemberAIProfileParams{
		BudgetLevel: sql.NullString{
			String: req.BudgetLevel,
			Valid:  req.BudgetLevel != "",
		},
		ProfilePictureUrl: sql.NullString{
			String: req.ProfilePictureURL,
			Valid:  req.ProfilePictureURL != "",
		},
	}

	// Check limit if profile picture is being updated
	if req.ProfilePictureURL != "" && (member.ProfilePictureURL == nil || *member.ProfilePictureURL != req.ProfilePictureURL) {
		count, err := h.aiRepo.CountProfilePictureUpdates(ctx, sqlcdb.CountProfilePictureUpdatesParams{
			MemberID:      member.ID,
			UpdatedByRole: "member",
		})
		if err != nil {
			h.log.Error("Failed to count profile picture updates", "member_id", member.ID, "error", err)
			return utils.ErrorResponse(c, fiber.StatusInternalServerError, "INTERNAL_ERROR", "Failed to verify update limits", nil)
		}

		if count >= 3 {
			return utils.ErrorResponse(c, fiber.StatusForbidden, "LIMIT_REACHED", "You have reached the maximum allowed profile picture updates (3).", nil)
		}

		// Record the update
		_, err = h.aiRepo.RecordProfilePictureUpdate(ctx, sqlcdb.RecordProfilePictureUpdateParams{
			MemberID:      member.ID,
			UpdatedByRole: "member",
			UpdatedByID:   member.ID,
		})
		if err != nil {
			h.log.Error("Failed to record profile picture update", "member_id", member.ID, "error", err)
			return utils.ErrorResponse(c, fiber.StatusInternalServerError, "INTERNAL_ERROR", "Failed to record profile picture update", nil)
		}
	}

	// Update the profile in the database
	_, err := h.aiRepo.UpdateMemberAIProfile(ctx, sqlcdb.UpdateMemberAIProfileParams{
		ID:                member.ID,
		BudgetLevel:       arg.BudgetLevel,
		IsAiAllowed:       member.IsAIAllowed, // Retain existing value
		ProfilePictureUrl: arg.ProfilePictureUrl,
	})

	if err != nil {
		h.log.Error("Failed to update AI profile", "member_id", member.ID, "error", err)
		return utils.ErrorResponse(c, fiber.StatusInternalServerError, "INTERNAL_ERROR", "Failed to update AI profile", nil)
	}

	return utils.SuccessResponse(c, fiber.StatusOK, nil)
}

// GetFoodLogs
//
//	@Summary		List Food Logs
//	@Description	Returns all food log entries for the authenticated member, including AI nutrition analysis.
//	@Tags			AI
//	@Produce		json
//	@Security		BearerAuth
//	@Param			limit	query	int	false	"Max records to return (default 20)"
//	@Param			offset	query	int	false	"Offset for pagination (default 0)"
//	@Success		200	{object}	response.Response
//	@Failure		500	{object}	response.Response
//	@Router			/api/v1/ai/food-logs [get]
func (h *AIHandler) GetFoodLogs(c *fiber.Ctx) error {
	ctx := c.UserContext()
	member, _ := c.Locals("member_obj").(*models.Member)

	limit := int32(c.QueryInt("limit", 20))
	offset := int32(c.QueryInt("offset", 0))

	logs, err := h.aiRepo.ListMemberFoodLogs(ctx, sqlcdb.ListMemberFoodLogsParams{
		MemberID: member.ID,
		Limit:    limit,
		Offset:   offset,
	})
	if err != nil {
		h.log.Error("Failed to list food logs", "member_id", member.ID, "error", err)
		return utils.ErrorResponse(c, fiber.StatusInternalServerError, "INTERNAL_ERROR", "Failed to retrieve food logs", nil)
	}

	return utils.SuccessResponse(c, fiber.StatusOK, logs)
}
