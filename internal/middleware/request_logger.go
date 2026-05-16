package middleware

import (
	"log/slog"
	"time"

	applogger "github.com/asadlive84/fitness-care-bagerhat/internal/logger"
	"github.com/gofiber/fiber/v2"
)

// RequestLogger logs every HTTP request with method, path, status, latency,
// IP, user agent, request ID, and user ID (if authenticated).
func RequestLogger(log *slog.Logger) fiber.Handler {
	return func(c *fiber.Ctx) error {
		start := time.Now()

		err := c.Next()

		latency := time.Since(start).Milliseconds()
		ctx := c.UserContext()

		log.InfoContext(ctx, "request completed",
			slog.String("request_id", applogger.RequestIDFromContext(ctx)),
			slog.String("method", c.Method()),
			slog.String("path", c.Path()),
			slog.Int("status", c.Response().StatusCode()),
			slog.Int64("latency_ms", latency),
			slog.String("ip", c.IP()),
			slog.String("user_agent", c.Get(fiber.HeaderUserAgent)),
			slog.String("user_id", applogger.UserIDFromContext(ctx)),
		)

		return err
	}
}
