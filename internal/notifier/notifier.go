// Package notifier abstracts push notification delivery.
// The service uses the Notifier interface; concrete implementations are
// FCMNotifier (production) and NoopNotifier (local dev / testing).
package notifier

import "context"

// Notifier sends a push notification to a single FCM device token.
type Notifier interface {
	Send(ctx context.Context, token, title, body string, data map[string]string) error
}
