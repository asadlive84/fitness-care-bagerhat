package notifier

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log/slog"
	"net/http"

	"golang.org/x/oauth2"
	"golang.org/x/oauth2/google"
)

const fcmScope = "https://www.googleapis.com/auth/firebase.messaging"

// FCMNotifier sends push notifications via the FCM HTTP v1 API.
// Uses service account credentials for OAuth2 — no Firebase Admin SDK required.
type FCMNotifier struct {
	projectID string
	ts        oauth2.TokenSource
	client    *http.Client
	log       *slog.Logger
}

// NewFCMNotifier initialises an FCMNotifier from a service-account credentials JSON string.
// Returns an error if the credentials are invalid.
func NewFCMNotifier(ctx context.Context, projectID, credentialsJSON string, log *slog.Logger) (*FCMNotifier, error) {
	if projectID == "" || credentialsJSON == "" {
		return nil, fmt.Errorf("FCM_PROJECT_ID and FIREBASE_CREDENTIALS_JSON must both be set")
	}

	creds, err := google.CredentialsFromJSON(ctx, []byte(credentialsJSON), fcmScope)
	if err != nil {
		return nil, fmt.Errorf("parse FCM credentials: %w", err)
	}

	return &FCMNotifier{
		projectID: projectID,
		ts:        creds.TokenSource,
		client:    &http.Client{},
		log:       log,
	}, nil
}

// Send delivers a push notification to a single FCM token.
func (n *FCMNotifier) Send(ctx context.Context, token, title, body string, data map[string]string) error {
	tok, err := n.ts.Token()
	if err != nil {
		return fmt.Errorf("get FCM access token: %w", err)
	}

	payload := map[string]any{
		"message": map[string]any{
			"token": token,
			"notification": map[string]string{
				"title": title,
				"body":  body,
			},
			"data": data,
		},
	}

	buf, _ := json.Marshal(payload)
	url := fmt.Sprintf("https://fcm.googleapis.com/v1/projects/%s/messages:send", n.projectID)

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, url, bytes.NewReader(buf))
	if err != nil {
		return fmt.Errorf("build FCM request: %w", err)
	}
	req.Header.Set("Authorization", "Bearer "+tok.AccessToken)
	req.Header.Set("Content-Type", "application/json")

	resp, err := n.client.Do(req)
	if err != nil {
		return fmt.Errorf("FCM request: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		return fmt.Errorf("FCM returned %d: %s", resp.StatusCode, body)
	}
	return nil
}
