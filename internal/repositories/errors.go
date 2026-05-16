package repositories

import "errors"

// Sentinel errors returned by repository implementations.
// Services and handlers check these with errors.Is to map to the correct
// HTTP status code without importing database-driver-specific types.
var (
	ErrNotFound    = errors.New("not found")
	ErrConflict    = errors.New("already exists")    // unique constraint violation
	ErrFKViolation = errors.New("referenced record in use or does not exist") // FK constraint
)
