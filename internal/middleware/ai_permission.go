package middleware

import (
	"log/slog"
	"strconv"
	"strings"
	"time"

	"github.com/asadlive84/fitness-care-bagerhat/internal/database/sqlc"
	"github.com/asadlive84/fitness-care-bagerhat/internal/models"
	"github.com/asadlive84/fitness-care-bagerhat/internal/repositories/postgres"
	"github.com/asadlive84/fitness-care-bagerhat/internal/utils"
	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
)

// RequireAIPermission checks if AI features are globally enabled and if the user is allowed.
func RequireAIPermission(aiRepo *postgres.AIRepo, memberRepo *postgres.MemberRepo, log *slog.Logger) fiber.Handler {
	return func(c *fiber.Ctx) error {
		ctx := c.UserContext()

		// 1. Fetch member profile first to resolve lineage (CreatedByAdminID)
		userIDStr, ok := c.Locals("user_id").(string)
		if !ok {
			return utils.ErrorResponse(c, fiber.StatusUnauthorized, "UNAUTHORIZED", "Missing user ID", nil)
		}

		userID, err := uuid.Parse(userIDStr)
		if err != nil {
			return utils.ErrorResponse(c, fiber.StatusBadRequest, "BAD_REQUEST", "Invalid user ID", nil)
		}

		member, err := memberRepo.GetByID(ctx, userID)
		if err != nil {
			return utils.ErrorResponse(c, fiber.StatusInternalServerError, "INTERNAL_ERROR", "Failed to fetch member profile", nil)
		}

		// Save the member object to avoid refetching in handlers
		c.Locals("member_obj", member)

		// 2. Check global kill switch scoped by admin_id override!
		setting, err := aiRepo.GetSystemSetting(ctx, "is_global_ai_enabled", member.CreatedByAdminID)
		if err == nil && setting.SettingValue != "true" {
			log.Warn("AI access blocked globally", "admin_id", member.CreatedByAdminID)
			return utils.ErrorResponse(c, fiber.StatusServiceUnavailable, "SERVICE_UNAVAILABLE", "AI features are currently disabled globally", nil)
		}

		// 3. Check member permissions
		path := c.Path()
		if strings.Contains(path, "/food-log") || strings.Contains(path, "/food-logs") {
			if !member.IsAIFoodLogAllowed {
				return utils.ErrorResponse(c, fiber.StatusForbidden, "FORBIDDEN", "You do not have permission to use AI Food Log features", nil)
			}
		} else if strings.Contains(path, "/diet-chart") {
			if !member.IsAIAllowed {
				return utils.ErrorResponse(c, fiber.StatusForbidden, "FORBIDDEN", "You do not have permission to use AI Diet Chart features", nil)
			}
		} else {
			// Profile or general endpoints: allowed if either is enabled
			if !member.IsAIAllowed && !member.IsAIFoodLogAllowed {
				return utils.ErrorResponse(c, fiber.StatusForbidden, "FORBIDDEN", "You do not have permission to use AI features", nil)
			}
		}

		return c.Next()
	}
}

// RequireDailyFoodLimit checks if the member has reached their daily AI food upload limit.
func RequireDailyFoodLimit(aiRepo *postgres.AIRepo, log *slog.Logger) fiber.Handler {
	return func(c *fiber.Ctx) error {
		ctx := c.UserContext()
		userIDStr := c.Locals("user_id").(string)
		userID := uuid.MustParse(userIDStr)

		var createdByAdminID *uuid.UUID
		if member, ok := c.Locals("member_obj").(*models.Member); ok && member != nil {
			createdByAdminID = member.CreatedByAdminID
		}

		// Get max limit scoped by admin lineage!
		limitSetting, err := aiRepo.GetSystemSetting(ctx, "max_daily_food_uploads", createdByAdminID)
		maxLimit := int64(5) // default
		if err == nil {
			if parsed, err := strconv.ParseInt(limitSetting.SettingValue, 10, 64); err == nil {
				maxLimit = parsed
			}
		}

		// Count today's uploads
		count, err := aiRepo.CountDailyFoodUploads(ctx, sqlcdb.CountDailyFoodUploadsParams{
			MemberID: userID,
			LogDate:  time.Now(),
		})
		if err != nil {
			return utils.ErrorResponse(c, fiber.StatusInternalServerError, "INTERNAL_ERROR", "Failed to check limits", nil)
		}

		if count >= maxLimit {
			return utils.ErrorResponse(c, fiber.StatusTooManyRequests, "RATE_LIMITED", "Daily food analysis limit reached", nil)
		}

		return c.Next()
	}
}
