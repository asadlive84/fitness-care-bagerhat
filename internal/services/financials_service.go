package services

import (
	"context"
	"fmt"
	"time"

	"github.com/asadlive84/fitness-care-bagerhat/internal/models"
	"github.com/asadlive84/fitness-care-bagerhat/internal/repositories"
)

// FinancialsService handles consolidated financial analytics and timelines.
type FinancialsService struct {
	repo     repositories.FinancialRepository
	timezone string
}

// NewFinancialsService creates a new FinancialsService.
func NewFinancialsService(repo repositories.FinancialRepository, timezone string) *FinancialsService {
	return &FinancialsService{
		repo:     repo,
		timezone: timezone,
	}
}

// GetFinancialsReport aggregates income and costs into a single, centralized analytics payload.
func (s *FinancialsService) GetFinancialsReport(ctx context.Context, start, end time.Time) (*models.FinancialsReport, error) {
	loc, err := time.LoadLocation(s.timezone)
	if err != nil {
		loc = time.UTC
	}

	// Align dates to start and end of day under business timezone
	tzStart := time.Date(start.Year(), start.Month(), start.Day(), 0, 0, 0, 0, loc)
	tzEnd := time.Date(end.Year(), end.Month(), end.Day(), 23, 59, 59, 999999999, loc)

	// Fetch timeline (daily income and expense aggregates)
	timeline, err := s.repo.GetDailyTimeline(ctx, tzStart, tzEnd, s.timezone)
	if err != nil {
		return nil, fmt.Errorf("timeline aggregates: %w", err)
	}

	// Fetch payments grouped by plan type
	byPlan, err := s.repo.GetRevenueByPlan(ctx, tzStart, tzEnd)
	if err != nil {
		return nil, fmt.Errorf("revenue by plan: %w", err)
	}

	// Fetch payments grouped by payment method
	byMethod, err := s.repo.GetRevenueByMethod(ctx, tzStart, tzEnd)
	if err != nil {
		return nil, fmt.Errorf("revenue by method: %w", err)
	}

	// Fetch expenses grouped by category
	byCategory, err := s.repo.GetExpensesByCategory(ctx, tzStart, tzEnd)
	if err != nil {
		return nil, fmt.Errorf("expenses by category: %w", err)
	}

	// Calculate totals based on groupings
	var totalIncome float64
	for _, p := range byPlan {
		totalIncome += p.TotalAmount
	}

	var totalCost float64
	for _, c := range byCategory {
		totalCost += c.TotalAmount
	}

	netProfit := totalIncome - totalCost

	return &models.FinancialsReport{
		StartDate:          tzStart,
		EndDate:            tzEnd,
		TotalIncome:        totalIncome,
		TotalCost:          totalCost,
		NetProfit:          netProfit,
		Timeline:           timeline,
		RevenueByPlan:      byPlan,
		RevenueByMethod:    byMethod,
		ExpensesByCategory: byCategory,
	}, nil
}
