package middleware

import (
	"strings"

	appauth "github.com/asadlive84/fitness-care-bagerhat/internal/auth"
	applogger "github.com/asadlive84/fitness-care-bagerhat/internal/logger"
	"github.com/asadlive84/fitness-care-bagerhat/internal/utils"
	"github.com/gofiber/fiber/v2"
)

// RequireAuth validates the Bearer token in the Authorization header.
// On success it stores user_id and role in Fiber locals and the Go context.
func RequireAuth(jwtManager *appauth.Manager) fiber.Handler {
	return func(c *fiber.Ctx) error {
		token := extractBearer(c)
		if token == "" {
			return utils.ErrorResponse(c, fiber.StatusUnauthorized,
				"UNAUTHORIZED", "Missing authentication token", nil)
		}

		claims, err := jwtManager.ValidateAccessToken(token)
		if err != nil {
			return utils.ErrorResponse(c, fiber.StatusUnauthorized,
				"UNAUTHORIZED", "Invalid or expired token", nil)
		}

		c.Locals("user_id", claims.Subject)
		c.Locals("role", claims.Role)

		// Propagate user ID into the Go context so the logger picks it up.
		ctx := applogger.WithUserID(c.UserContext(), claims.Subject)
		c.SetUserContext(ctx)

		return c.Next()
	}
}

// RequireRole checks that the authenticated user has one of the allowed roles.
// Must be used after RequireAuth.
func RequireRole(roles ...string) fiber.Handler {
	return func(c *fiber.Ctx) error {
		role, _ := c.Locals("role").(string)
		for _, r := range roles {
			if r == role {
				return c.Next()
			}
		}
		return utils.ErrorResponse(c, fiber.StatusForbidden,
			"FORBIDDEN", "You do not have permission to access this resource", nil)
	}
}

func extractBearer(c *fiber.Ctx) string {
	header := c.Get(fiber.HeaderAuthorization)
	if !strings.HasPrefix(header, "Bearer ") {
		return ""
	}
	return strings.TrimPrefix(header, "Bearer ")
}
