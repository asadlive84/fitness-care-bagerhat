package services

import (
	"context"
	"fmt"
	"time"

	"github.com/asadlive84/fitness-care-bagerhat/internal/models"
	"github.com/asadlive84/fitness-care-bagerhat/internal/repositories"
	"github.com/google/uuid"
)

// ── WeightLogService ──────────────────────────────────────────────────────────

// WeightLogService handles weight log business logic.
type WeightLogService struct {
	logs    repositories.WeightLogRepository
	members repositories.MemberRepository
}

// NewWeightLogService constructs a WeightLogService.
func NewWeightLogService(logs repositories.WeightLogRepository, members repositories.MemberRepository) *WeightLogService {
	return &WeightLogService{logs: logs, members: members}
}

// LogWeight records a new weight entry. loggedAt defaults to now if zero.
func (s *WeightLogService) LogWeight(ctx context.Context, memberID uuid.UUID, weightKg float64, loggedAt time.Time) (*models.WeightLog, error) {
	if loggedAt.IsZero() {
		loggedAt = time.Now()
	}
	if err := s.logs.Create(ctx, memberID, weightKg, loggedAt); err != nil {
		return nil, fmt.Errorf("log weight: %w", err)
	}

	// Update the member's current_weight so the profile reflects the latest log
	if m, err := s.members.GetByID(ctx, memberID); err == nil {
		m.CurrentWeight = &weightKg
		_ = s.members.Update(ctx, m)
	}

	return &models.WeightLog{ID: uuid.New(), MemberID: memberID, WeightKg: weightKg, LoggedAt: loggedAt}, nil
}

// ListWeightLogs returns weight logs for a member with optional date bounds.
// nil from/to means no bound on that side.
func (s *WeightLogService) ListWeightLogs(ctx context.Context, memberID uuid.UUID, from, to *time.Time) ([]models.WeightLog, error) {
	f := normalizeFrom(from)
	t := normalizeTo(to)
	logs, err := s.logs.ListByMemberAndDateRange(ctx, memberID, f, t)
	if err != nil {
		return nil, fmt.Errorf("list weight logs: %w", err)
	}
	return logs, nil
}

// ── WorkoutLogService ─────────────────────────────────────────────────────────

// WorkoutLogService handles workout log business logic.
type WorkoutLogService struct {
	logs repositories.WorkoutLogRepository
}

// NewWorkoutLogService constructs a WorkoutLogService.
func NewWorkoutLogService(logs repositories.WorkoutLogRepository) *WorkoutLogService {
	return &WorkoutLogService{logs: logs}
}

// LogWorkout records a new workout entry.
func (s *WorkoutLogService) LogWorkout(ctx context.Context, memberID uuid.UUID, content string, loggedAt time.Time) (*models.WorkoutLog, error) {
	if loggedAt.IsZero() {
		loggedAt = time.Now()
	}
	if err := s.logs.Create(ctx, memberID, content, loggedAt); err != nil {
		return nil, fmt.Errorf("log workout: %w", err)
	}
	return &models.WorkoutLog{ID: uuid.New(), MemberID: memberID, Content: content, LoggedAt: loggedAt}, nil
}

// ListWorkoutLogs returns paginated workout logs for a member.
func (s *WorkoutLogService) ListWorkoutLogs(ctx context.Context, memberID uuid.UUID, page, limit int) ([]models.WorkoutLog, error) {
	logs, err := s.logs.ListByMemberID(ctx, memberID, page, limit)
	if err != nil {
		return nil, fmt.Errorf("list workout logs: %w", err)
	}
	return logs, nil
}

// ── DietLogService ────────────────────────────────────────────────────────────

// DietLogService handles diet log business logic.
type DietLogService struct {
	logs repositories.DietLogRepository
}

// NewDietLogService constructs a DietLogService.
func NewDietLogService(logs repositories.DietLogRepository) *DietLogService {
	return &DietLogService{logs: logs}
}

// LogDiet records a new diet entry.
func (s *DietLogService) LogDiet(ctx context.Context, memberID uuid.UUID, content string, loggedAt time.Time) (*models.DietLog, error) {
	if loggedAt.IsZero() {
		loggedAt = time.Now()
	}
	if err := s.logs.Create(ctx, memberID, content, loggedAt); err != nil {
		return nil, fmt.Errorf("log diet: %w", err)
	}
	return &models.DietLog{ID: uuid.New(), MemberID: memberID, Content: content, LoggedAt: loggedAt}, nil
}

// ListDietLogs returns paginated diet logs for a member.
func (s *DietLogService) ListDietLogs(ctx context.Context, memberID uuid.UUID, page, limit int) ([]models.DietLog, error) {
	logs, err := s.logs.ListByMemberID(ctx, memberID, page, limit)
	if err != nil {
		return nil, fmt.Errorf("list diet logs: %w", err)
	}
	return logs, nil
}

// ── helpers ───────────────────────────────────────────────────────────────────

// normalizeFrom returns from if set, otherwise the Unix epoch (no lower bound).
func normalizeFrom(from *time.Time) time.Time {
	if from != nil {
		return *from
	}
	return time.Unix(0, 0)
}

// normalizeTo returns to if set, otherwise far future (no upper bound).
func normalizeTo(to *time.Time) time.Time {
	if to != nil {
		return *to
	}
	return time.Now().AddDate(100, 0, 0)
}
