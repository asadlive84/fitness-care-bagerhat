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
	case "uuid":
		return "Must be a valid UUID"
	case "min":
		if isNumericKind(e) {
			return fmt.Sprintf("Must be at least %s", e.Param())
		}
		return fmt.Sprintf("Must be at least %s characters", e.Param())
	case "max":
		if isNumericKind(e) {
			return fmt.Sprintf("Must be at most %s", e.Param())
		}
		return fmt.Sprintf("Must be at most %s characters", e.Param())
	case "gt":
		return fmt.Sprintf("Must be greater than %s", e.Param())
	case "gte":
		return fmt.Sprintf("Must be %s or greater", e.Param())
	case "oneof":
		return fmt.Sprintf("Must be one of: %s", e.Param())
	default:
		return fmt.Sprintf("Failed validation: %s", e.Tag())
	}
}

// isNumericKind reports whether the validated field is a numeric type so that
// min/max error messages omit the word "characters".
func isNumericKind(e validator.FieldError) bool {
	switch e.Kind().String() {
	case "int", "int8", "int16", "int32", "int64",
		"uint", "uint8", "uint16", "uint32", "uint64",
		"float32", "float64":
		return true
	default:
		return false
	}
}
