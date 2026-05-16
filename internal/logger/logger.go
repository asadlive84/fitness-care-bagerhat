package logger

import (
	"context"
	"io"
	"log/slog"
	"os"

	"github.com/asadlive84/fitness-care-bagerhat/internal/config"
)

type contextKey string

const requestIDKey contextKey = "request_id"
const userIDKey contextKey = "user_id"

// New creates the application logger.
// In production: JSON to stdout + async DB sink.
// In development: pretty text to stdout + async DB sink.
func New(cfg *config.Config, dbSink io.Writer) *slog.Logger {
	var handler slog.Handler

	opts := &slog.HandlerOptions{Level: slog.LevelDebug}

	if cfg.App.Env == "production" {
		handler = slog.NewJSONHandler(io.MultiWriter(os.Stdout, dbSink), opts)
	} else {
		handler = slog.NewTextHandler(io.MultiWriter(os.Stdout, dbSink), opts)
	}

	return slog.New(handler)
}

// WithRequestID attaches a request ID to the context.
func WithRequestID(ctx context.Context, id string) context.Context {
	return context.WithValue(ctx, requestIDKey, id)
}

// RequestIDFromContext retrieves the request ID from context.
func RequestIDFromContext(ctx context.Context) string {
	if id, ok := ctx.Value(requestIDKey).(string); ok {
		return id
	}
	return ""
}

// WithUserID attaches an authenticated user ID to the context.
func WithUserID(ctx context.Context, id string) context.Context {
	return context.WithValue(ctx, userIDKey, id)
}

// UserIDFromContext retrieves the user ID from context.
func UserIDFromContext(ctx context.Context) string {
	if id, ok := ctx.Value(userIDKey).(string); ok {
		return id
	}
	return ""
}

// FromContext returns a logger enriched with request_id and user_id from ctx.
func FromContext(ctx context.Context, base *slog.Logger) *slog.Logger {
	args := []any{}
	if rid := RequestIDFromContext(ctx); rid != "" {
		args = append(args, slog.String("request_id", rid))
	}
	if uid := UserIDFromContext(ctx); uid != "" {
		args = append(args, slog.String("user_id", uid))
	}
	if len(args) == 0 {
		return base
	}
	return base.With(args...)
}
