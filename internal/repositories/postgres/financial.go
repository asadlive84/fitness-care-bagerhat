package postgres

import (
	"context"
	"database/sql"
	"fmt"
	"time"

	sqlcdb "github.com/asadlive84/fitness-care-bagerhat/internal/database/sqlc"
	"github.com/asadlive84/fitness-care-bagerhat/internal/models"
)

// FinancialRepo is a pure Postgres implementation for centralized financials.
type FinancialRepo struct {
	q  *sqlcdb.Queries
	db *sql.DB
}

// NewFinancialRepo creates a new FinancialRepo.
func NewFinancialRepo(db *sql.DB) *FinancialRepo {
	return &FinancialRepo{q: sqlcdb.New(db), db: db}
}

func (r *FinancialRepo) GetDailyTimeline(ctx context.Context, startDate, endDate time.Time, timezone string) ([]*models.DailyFinancial, error) {
	params := sqlcdb.GetDailyFinancialsByMonthParams{
		StartDate: startDate,
		EndDate:   endDate,
		Timezone:  timezone,
	}

	rows, err := r.q.GetDailyFinancialsByMonth(ctx, params)
	if err != nil {
		return nil, fmt.Errorf("daily timeline: %w", err)
	}

	financials := make([]*models.DailyFinancial, len(rows))
	for i, row := range rows {
		financials[i] = &models.DailyFinancial{
			Date:     row.Date,
			Earnings: row.Earnings,
			Expenses: row.Expenses,
			Net:      row.Net,
		}
	}

	return financials, nil
}

func (r *FinancialRepo) GetRevenueByPlan(ctx context.Context, startDate, endDate time.Time) ([]*models.PlanRevenueBreakdown, error) {
	params := sqlcdb.GetRevenueByPlanTypeParams{
		StartDate: startDate,
		EndDate:   endDate,
	}

	rows, err := r.q.GetRevenueByPlanType(ctx, params)
	if err != nil {
		return nil, fmt.Errorf("revenue by plan: %w", err)
	}

	breakdowns := make([]*models.PlanRevenueBreakdown, len(rows))
	for i, row := range rows {
		breakdowns[i] = &models.PlanRevenueBreakdown{
			PlanName:         row.PlanName,
			PlanPrice:        row.PlanPrice,
			TotalAmount:      row.TotalAmount,
			TransactionCount: row.TransactionCount,
		}
	}

	return breakdowns, nil
}

func (r *FinancialRepo) GetRevenueByMethod(ctx context.Context, startDate, endDate time.Time) ([]*models.MethodRevenueBreakdown, error) {
	params := sqlcdb.GetRevenueByPaymentMethodParams{
		StartDate: startDate,
		EndDate:   endDate,
	}

	rows, err := r.q.GetRevenueByPaymentMethod(ctx, params)
	if err != nil {
		return nil, fmt.Errorf("revenue by method: %w", err)
	}

	breakdowns := make([]*models.MethodRevenueBreakdown, len(rows))
	for i, row := range rows {
		breakdowns[i] = &models.MethodRevenueBreakdown{
			PaymentMethod:    row.PaymentMethod,
			TotalAmount:      row.TotalAmount,
			TransactionCount: row.TransactionCount,
		}
	}

	return breakdowns, nil
}

func (r *FinancialRepo) GetExpensesByCategory(ctx context.Context, startDate, endDate time.Time) ([]*models.CategoryExpenseBreakdown, error) {
	params := sqlcdb.GetExpensesByCategoryParams{
		StartDate: startDate,
		EndDate:   endDate,
	}

	rows, err := r.q.GetExpensesByCategory(ctx, params)
	if err != nil {
		return nil, fmt.Errorf("expenses by category: %w", err)
	}

	breakdowns := make([]*models.CategoryExpenseBreakdown, len(rows))
	for i, row := range rows {
		breakdowns[i] = &models.CategoryExpenseBreakdown{
			Category:     row.Category,
			TotalAmount:  row.TotalAmount,
			ExpenseCount: row.ExpenseCount,
		}
	}

	return breakdowns, nil
}
