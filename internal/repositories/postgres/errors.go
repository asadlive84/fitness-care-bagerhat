package postgres

import (
	"database/sql"
	"errors"

	"github.com/asadlive84/fitness-care-bagerhat/internal/repositories"
	"github.com/lib/pq"
)

// mapErr converts known database/driver errors to repository sentinels so
// callers never have to import database-driver-specific types.
func mapErr(err error) error {
	if err == nil {
		return nil
	}
	if errors.Is(err, sql.ErrNoRows) {
		return repositories.ErrNotFound
	}
	var pqErr *pq.Error
	if errors.As(err, &pqErr) {
		switch pqErr.Code {
		case "23505": // unique_violation
			return repositories.ErrConflict
		case "23503": // foreign_key_violation
			return repositories.ErrFKViolation
		}
	}
	return err
}
