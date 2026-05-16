package utils

import "github.com/gofiber/fiber/v2"

// SuccessResponse wraps data in the standard success envelope.
func SuccessResponse(c *fiber.Ctx, status int, data any) error {
	return c.Status(status).JSON(fiber.Map{
		"success": true,
		"data":    data,
	})
}

// PaginatedResponse wraps paginated data with meta.
func PaginatedResponse(c *fiber.Ctx, data any, page, limit, total int) error {
	return c.Status(fiber.StatusOK).JSON(fiber.Map{
		"success": true,
		"data":    data,
		"meta": fiber.Map{
			"page":  page,
			"limit": limit,
			"total": total,
		},
	})
}

// ErrorResponse returns a standardised error envelope.
func ErrorResponse(c *fiber.Ctx, status int, code, message string, details any) error {
	body := fiber.Map{
		"success": false,
		"error": fiber.Map{
			"code":    code,
			"message": message,
		},
	}
	if details != nil {
		body["error"].(fiber.Map)["details"] = details
	}
	return c.Status(status).JSON(body)
}
