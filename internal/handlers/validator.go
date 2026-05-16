package handlers

import (
	"fmt"

	"github.com/go-playground/validator/v10"
	"github.com/gofiber/fiber/v2"
)

// validate is a package-level singleton; it is goroutine-safe after init.
var validate = validator.New()

// parseAndValidate parses the JSON body into dst and runs struct validation.
// On failure it writes the error response and returns false — the caller must
// return nil immediately (response is already committed).
// On success it returns true and the caller continues normally.
func parseAndValidate(c *fiber.Ctx, dst any) bool {
	if err := c.BodyParser(dst); err != nil {
		c.Status(fiber.StatusBadRequest).JSON(fiber.Map{ //nolint:errcheck
			"success": false,
			"error": fiber.Map{
				"code":    "INVALID_JSON",
				"message": "Request body is not valid JSON",
			},
		})
		return false
	}

	if err := validate.Struct(dst); err != nil {
		c.Status(fiber.StatusBadRequest).JSON(fiber.Map{ //nolint:errcheck
			"success": false,
			"error": fiber.Map{
				"code":    "VALIDATION_ERROR",
				"message": "One or more fields are invalid",
				"details": formatValidationErrors(err),
			},
		})
		return false
	}

	return true
}

func formatValidationErrors(err error) map[string]string {
	out := make(map[string]string)
	if errs, ok := err.(validator.ValidationErrors); ok {
		for _, e := range errs {
			out[e.Field()] = fieldErrMsg(e)
		}
	}
	return out
}

func fieldErrMsg(e validator.FieldError) string {
	switch e.Tag() {
	case "required":
		return "This field is required"
	case "email":
		return "Must be a valid email address"
	case "min":
		return fmt.Sprintf("Must be at least %s characters", e.Param())
	case "max":
		return fmt.Sprintf("Must be at most %s characters", e.Param())
	case "oneof":
		return fmt.Sprintf("Must be one of: %s", e.Param())
	default:
		return fmt.Sprintf("Failed validation: %s", e.Tag())
	}
}
