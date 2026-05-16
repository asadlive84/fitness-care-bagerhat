// Package scheduler runs background cron jobs for renewal reminders,
// weight reminders, and notification dispatch with quiet-window enforcement.
package scheduler

import (
	"context"
	"encoding/json"
	"log/slog"
	"time"

	"github.com/asadlive84/fitness-care-bagerhat/internal/models"
	"github.com/asadlive84/fitness-care-bagerhat/internal/notifier"
	"github.com/asadlive84/fitness-care-bagerhat/internal/repositories"
	"github.com/asadlive84/fitness-care-bagerhat/internal/services"
	"github.com/google/uuid"
	"github.com/robfig/cron/v3"
)

// Scheduler owns the cron runner and all background jobs.
type Scheduler struct {
	cron      *cron.Cron
	settings  *services.SettingService
	members   repositories.MemberRepository
	subs      repositories.SubscriptionRepository
	weights   repositories.WeightLogRepository
	notifs    repositories.NotificationRepository
	fcmTokens repositories.FCMTokenRepository
	sender    notifier.Notifier
	tz        *time.Location
	log       *slog.Logger
}

// New builds a Scheduler with the given timezone string (e.g. "Asia/Dhaka").
func New(
	tz *time.Location,
	settings *services.SettingService,
	members repositories.MemberRepository,
	subs repositories.SubscriptionRepository,
	weights repositories.WeightLogRepository,
	notifs repositories.NotificationRepository,
	fcmTokens repositories.FCMTokenRepository,
	sender notifier.Notifier,
	log *slog.Logger,
) *Scheduler {
	s := &Scheduler{
		cron:      cron.New(cron.WithLocation(tz)),
		settings:  settings,
		members:   members,
		subs:      subs,
		weights:   weights,
		notifs:    notifs,
		fcmTokens: fcmTokens,
		sender:    sender,
		tz:        tz,
		log:       log,
	}
	s.register()
	return s
}

// Start launches the cron runner. Non-blocking.
func (s *Scheduler) Start() { s.cron.Start() }

// Stop gracefully shuts down the cron runner and waits for running jobs.
func (s *Scheduler) Stop() { <-s.cron.Stop().Done() }

// ── Job registration ──────────────────────────────────────────────────────────

func (s *Scheduler) register() {
	// Job 1: Renewal reminder — 9:00 AM every day
	s.cron.AddFunc("0 9 * * *", func() {
		ctx := context.Background()
		if err := s.renewalReminderJob(ctx); err != nil {
			s.log.Error("renewal reminder job failed", "error", err)
		}
	})

	// Job 2: Weight reminder — 8:00 AM every day
	s.cron.AddFunc("0 8 * * *", func() {
		ctx := context.Background()
		if err := s.weightReminderJob(ctx); err != nil {
			s.log.Error("weight reminder job failed", "error", err)
		}
	})

	// Job 3: Notification dispatch — every minute
	s.cron.AddFunc("* * * * *", func() {
		ctx := context.Background()
		if err := s.dispatchJob(ctx); err != nil {
			s.log.Error("notification dispatch job failed", "error", err)
		}
	})
}

// ── Job implementations ───────────────────────────────────────────────────────

// renewalReminderJob enqueues notifications for subscriptions expiring soon.
func (s *Scheduler) renewalReminderJob(ctx context.Context) error {
	nudgeDays := s.settings.GetNudgeDays(ctx)

	expiring, err := s.subs.ListExpiring(ctx, nudgeDays)
	if err != nil {
		return err
	}

	for _, es := range expiring {
		daysLeft := int(time.Until(es.EndDate).Hours() / 24)
		payload, _ := json.Marshal(models.RenewalPayload{
			MemberName: es.MemberName,
			EndDate:    es.EndDate,
			DaysLeft:   daysLeft,
		})

		n := &models.Notification{
			ID:          uuid.New(),
			MemberID:    es.MemberID,
			Type:        "renewal",
			Payload:     payload,
			ScheduledAt: time.Now(),
			Status:      "pending",
			CreatedAt:   time.Now(),
		}
		if err := s.notifs.Create(ctx, n); err != nil {
			s.log.Warn("enqueue renewal notification", "member_id", es.MemberID, "error", err)
		}
	}
	s.log.Info("renewal reminder job done", "enqueued", len(expiring))
	return nil
}

// weightReminderJob enqueues weight-log reminders for inactive members.
func (s *Scheduler) weightReminderJob(ctx context.Context) error {
	reminderDays := s.settings.GetWeightReminderDays(ctx)

	members, err := s.weights.ListMembersNeedingReminder(ctx, reminderDays)
	if err != nil {
		return err
	}

	for _, m := range members {
		payload, _ := json.Marshal(models.WeightReminderPayload{
			MemberName:   m.Name,
			DaysSinceLog: reminderDays,
		})

		n := &models.Notification{
			ID:          uuid.New(),
			MemberID:    m.ID,
			Type:        "weight_reminder",
			Payload:     payload,
			ScheduledAt: time.Now(),
			Status:      "pending",
			CreatedAt:   time.Now(),
		}
		if err := s.notifs.Create(ctx, n); err != nil {
			s.log.Warn("enqueue weight reminder", "member_id", m.ID, "error", err)
		}
	}
	s.log.Info("weight reminder job done", "enqueued", len(members))
	return nil
}

// dispatchJob sends pending notifications, enforcing the quiet window.
func (s *Scheduler) dispatchJob(ctx context.Context) error {
	pending, err := s.notifs.ListPending(ctx)
	if err != nil {
		return err
	}
	if len(pending) == 0 {
		return nil
	}

	window, _ := s.settings.GetQuietWindow(ctx)
	now := time.Now()

	sent, skipped, failed := 0, 0, 0
	for _, n := range pending {
		if notifier.IsInQuietWindow(now, window, s.tz) {
			// Reschedule to the end of the quiet window.
			end := notifier.WindowEnd(now, window, s.tz)
			if err := s.notifs.Reschedule(ctx, n.ID, end); err != nil {
				s.log.Warn("reschedule notification", "id", n.ID, "error", err)
			}
			skipped++
			continue
		}

		if err := s.sendToMember(ctx, n); err != nil {
			s.log.Warn("send notification failed", "id", n.ID, "error", err)
			s.notifs.UpdateStatus(ctx, n.ID, "failed") //nolint:errcheck
			failed++
			continue
		}
		s.notifs.UpdateStatus(ctx, n.ID, "sent") //nolint:errcheck
		sent++
	}

	s.log.Info("dispatch job done",
		"sent", sent, "rescheduled", skipped, "failed", failed)
	return nil
}

// sendToMember sends the notification to all of the member's FCM tokens.
func (s *Scheduler) sendToMember(ctx context.Context, n *models.Notification) error {
	tokens, err := s.fcmTokens.ListTokensByMember(ctx, n.MemberID)
	if err != nil || len(tokens) == 0 {
		return nil // no tokens → nothing to send, not an error
	}

	title, body := titleAndBody(n)
	data := map[string]string{"type": n.Type, "notification_id": n.ID.String()}

	var lastErr error
	for _, tok := range tokens {
		if err := s.sender.Send(ctx, tok, title, body, data); err != nil {
			s.log.Warn("FCM send failed", "token_prefix", safeToken(tok), "error", err)
			lastErr = err
		}
	}
	return lastErr
}

// ── helpers ───────────────────────────────────────────────────────────────────

func titleAndBody(n *models.Notification) (title, body string) {
	switch n.Type {
	case "renewal":
		var p models.RenewalPayload
		if json.Unmarshal(n.Payload, &p) == nil {
			return "Membership Expiring Soon",
				"Your membership expires in " + itoa(p.DaysLeft) + " days. Renew now!"
		}
	case "weight_reminder":
		return "Log Your Weight", "You haven't logged your weight in a while. Tap to update!"
	case "message":
		return "New Message", "You have a new message from the gym."
	}
	return "Gym Notification", ""
}

func itoa(n int) string {
	if n <= 0 {
		return "0"
	}
	s := ""
	for n > 0 {
		s = string(rune('0'+n%10)) + s
		n /= 10
	}
	return s
}

func safeToken(t string) string {
	if len(t) > 8 {
		return t[:8] + "..."
	}
	return t
}
