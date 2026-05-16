package notifier

import (
	"context"
	"log/slog"
)

// NoopNotifier logs notifications without sending them.
// Used in local dev and tests when Firebase credentials are not configured.
type NoopNotifier struct {
	log *slog.Logger
}

// NewNoopNotifier creates a NoopNotifier.
func NewNoopNotifier(log *slog.Logger) *NoopNotifier {
	return &NoopNotifier{log: log}
}

// Send logs the notification payload instead of calling FCM.
func (n *NoopNotifier) Send(_ context.Context, token, title, body string, _ map[string]string) error {
	safe := token
	if len(token) > 8 {
		safe = token[:8] + "..."
	}
	n.log.Info("noop FCM send",
		slog.String("token_prefix", safe),
		slog.String("title", title),
		slog.String("body", body),
	)
	return nil
}
