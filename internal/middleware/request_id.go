package middleware

import (
	applogger "github.com/asadlive84/fitness-care-bagerhat/internal/logger"
	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
)

const HeaderRequestID = "X-Request-ID"

// RequestID generates a UUID v4 request ID per request, attaches it to the
// Fiber locals (for handler access) and to the Go context (for service/repo layers).
func RequestID() fiber.Handler {
	return func(c *fiber.Ctx) error {
		id := c.Get(HeaderRequestID)
		if id == "" {
			id = uuid.NewString()
		}

		c.Set(HeaderRequestID, id)
		c.Locals("request_id", id)

		// Propagate into the Go context so logger.FromContext picks it up.
		ctx := applogger.WithRequestID(c.UserContext(), id)
		c.SetUserContext(ctx)

		return c.Next()
	}
}
