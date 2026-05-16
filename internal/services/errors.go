package services

import "errors"

// Sentinel errors returned by service methods and checked by handlers to map
// to the correct HTTP status code.
var (
	ErrInvalidCredentials = errors.New("invalid credentials")
	ErrMemberInactive     = errors.New("member account is inactive")
	ErrNotFound           = errors.New("not found")
	ErrConflict           = errors.New("conflict")
	ErrForbidden          = errors.New("forbidden")
	ErrPasswordRequired   = errors.New("password change required before accessing this resource")
)
