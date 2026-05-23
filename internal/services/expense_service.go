package services

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/asadlive84/fitness-care-bagerhat/internal/models"
	"github.com/asadlive84/fitness-care-bagerhat/internal/repositories"
	"github.com/google/uuid"
)

// ExpenseService handles all business logic regarding operational expenses.
type ExpenseService struct {
	repo     repositories.ExpenseRepository
	timezone string
}

// NewExpenseService creates a new ExpenseService.
func NewExpenseService(repo repositories.ExpenseRepository, timezone string) *ExpenseService {
	return &ExpenseService{
		repo:     repo,
		timezone: timezone,
	}
}

// RecordExpenseRequest holds fields for logging an expense.
type RecordExpenseRequest struct {
	Amount      float64   `json:"amount"`
	Description string    `json:"description"`
	Category    string    `json:"category"`
	SpentAt     time.Time `json:"spent_at"`
	RecordedBy  uuid.UUID `json:"recorded_by"`
}

// RecordExpense logs a new operational expense.
func (s *ExpenseService) RecordExpense(ctx context.Context, req RecordExpenseRequest) (*models.Expense, error) {
	if req.Amount <= 0 {
		return nil, errors.New("expense amount must be greater than zero")
	}
	if req.Description == "" {
		return nil, errors.New("expense description is required")
	}
	if req.Category == "" {
		return nil, errors.New("expense category is required")
	}

	loc, err := time.LoadLocation(s.timezone)
	if err != nil {
		loc = time.UTC
	}

	spentAt := req.SpentAt
	if spentAt.IsZero() {
		spentAt = time.Now().In(loc)
	}

	exp := &models.Expense{
		ID:          uuid.New(),
		Amount:      req.Amount,
		Description: req.Description,
		Category:    req.Category,
		SpentAt:     spentAt,
		RecordedBy:  req.RecordedBy,
	}

	if err := s.repo.Create(ctx, exp); err != nil {
		return nil, fmt.Errorf("create expense: %w", err)
	}

	return exp, nil
}

// ListExpenses returns paginated and filtered list of operational expenses.
func (s *ExpenseService) ListExpenses(ctx context.Context, filter models.ListExpensesFilter) ([]*models.Expense, int64, error) {
	return s.repo.List(ctx, filter)
}

// GetExpensesSummary returns a summary of operational expenses (Today, Yesterday, Month).
func (s *ExpenseService) GetExpensesSummary(ctx context.Context) (*models.ExpensesSummary, error) {
	loc, err := time.LoadLocation(s.timezone)
	if err != nil {
		loc = time.UTC
	}
	now := time.Now().In(loc)

	// Today bounds
	todayStart := time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, loc)
	todayEnd := todayStart.AddDate(0, 0, 1)

	// Yesterday bounds
	yesterdayStart := todayStart.AddDate(0, 0, -1)
	yesterdayEnd := todayStart

	// This Month bounds
	monthStart := time.Date(now.Year(), now.Month(), 1, 0, 0, 0, 0, loc)
	monthEnd := monthStart.AddDate(0, 1, 0)

	return s.repo.GetExpensesSummary(ctx, todayStart, todayEnd, yesterdayStart, yesterdayEnd, monthStart, monthEnd)
}

// GetDailyFinancials returns combined earnings and expenses for calendar ledger.
func (s *ExpenseService) GetDailyFinancials(ctx context.Context, month time.Time) ([]*models.DailyFinancial, error) {
	loc, err := time.LoadLocation(s.timezone)
	if err != nil {
		loc = time.UTC
	}

	// Calculate timezone-aware start and end dates of the requested month
	startOfMonth := time.Date(month.Year(), month.Month(), 1, 0, 0, 0, 0, loc)
	endOfMonth := startOfMonth.AddDate(0, 1, 0)

	return s.repo.GetDailyFinancials(ctx, startOfMonth, endOfMonth, s.timezone)
}
