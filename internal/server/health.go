package server

import (
	"database/sql"

	"github.com/asadlive84/fitness-care-bagerhat/internal/cache"
	"github.com/asadlive84/fitness-care-bagerhat/internal/database"
	"github.com/gofiber/fiber/v2"
)

// Healthz is the liveness probe — always returns 200 if the process is alive.
func Healthz(c *fiber.Ctx) error {
	return c.JSON(fiber.Map{"status": "ok"})
}

// ReadyzHandler returns a closure for the readiness probe.
// It checks Postgres and Redis. Redis down = degraded (200 with warning), not failed.
// Postgres down = unhealthy (503).
func ReadyzHandler(db *sql.DB, redisClient *cache.Client) fiber.Handler {
	return func(c *fiber.Ctx) error {
		ctx := c.UserContext()

		// Postgres is required.
		if err := database.Ping(ctx, db); err != nil {
			return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{
				"status": "unhealthy",
				"checks": fiber.Map{
					"postgres": "down: " + err.Error(),
					"redis":    "unknown",
				},
			})
		}

		// Redis is optional (graceful degradation).
		redisStatus := "ok"
		httpStatus := fiber.StatusOK
		if err := redisClient.Ping(ctx); err != nil {
			redisStatus = "degraded: " + err.Error()
			// Still 200 — Redis is a cache, not source of truth.
		}

		return c.Status(httpStatus).JSON(fiber.Map{
			"status": func() string {
				if redisStatus != "ok" {
					return "degraded"
				}
				return "ok"
			}(),
			"checks": fiber.Map{
				"postgres": "ok",
				"redis":    redisStatus,
			},
		})
	}
}
