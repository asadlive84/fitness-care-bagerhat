package postgres

import (
	"context"
	"database/sql"
	"fmt"
	"time"

	sqlcdb "github.com/asadlive84/fitness-care-bagerhat/internal/database/sqlc"
	"github.com/asadlive84/fitness-care-bagerhat/internal/models"
)

// ExpenseRepo is a pure Postgres implementation for expenses tracking.
type ExpenseRepo struct {
	q  *sqlcdb.Queries
	db *sql.DB
}

// NewExpenseRepo creates a new ExpenseRepo instance.
func NewExpenseRepo(db *sql.DB) *ExpenseRepo {
	return &ExpenseRepo{q: sqlcdb.New(db), db: db}
}

func (r *ExpenseRepo) Create(ctx context.Context, exp *models.Expense) error {
	_, err := r.q.CreateExpense(ctx, sqlcdb.CreateExpenseParams{
		ID:          exp.ID,
		Amount:      exp.Amount,
		Description: exp.Description,
		Category:    exp.Category,
		SpentAt:     exp.SpentAt,
		RecordedBy:  exp.RecordedBy,
	})
	return mapErr(err)
}

func (r *ExpenseRepo) List(ctx context.Context, filter models.ListExpensesFilter) ([]*models.Expense, int64, error) {
	limit := 20
	if filter.Limit > 0 {
		limit = filter.Limit
	}
	page := 1
	if filter.Page > 0 {
		page = filter.Page
	}
	offset := (page - 1) * limit

	params := sqlcdb.ListExpensesParams{
		FromTime:  nullTime(filter.From),
		ToTime:    nullTime(filter.To),
		LimitVal:  int32(limit),
		OffsetVal: int32(offset),
	}

	rows, err := r.q.ListExpenses(ctx, params)
	if err != nil {
		return nil, 0, fmt.Errorf("list expenses: %w", err)
	}

	countParams := sqlcdb.CountExpensesParams{
		FromTime: nullTime(filter.From),
		ToTime:   nullTime(filter.To),
	}

	total, err := r.q.CountExpenses(ctx, countParams)
	if err != nil {
		return nil, 0, fmt.Errorf("count expenses: %w", err)
	}

	expenses := make([]*models.Expense, len(rows))
	for i, row := range rows {
		expenses[i] = &models.Expense{
			ID:          row.ID,
			Amount:      row.Amount,
			Description: row.Description,
			Category:    row.Category,
			SpentAt:     row.SpentAt,
			RecordedBy:  row.RecordedBy,
			CreatedAt:   row.CreatedAt,
			UpdatedAt:   row.UpdatedAt,
		}
	}

	return expenses, total, nil
}

func (r *ExpenseRepo) GetExpensesSummary(ctx context.Context, todayStart, todayEnd, yesterdayStart, yesterdayEnd, monthStart, monthEnd time.Time) (*models.ExpensesSummary, error) {
	params := sqlcdb.GetExpensesSummaryParams{
		TodayStart:     todayStart,
		TodayEnd:       todayEnd,
		YesterdayStart: yesterdayStart,
		YesterdayEnd:   yesterdayEnd,
		MonthStart:     monthStart,
		MonthEnd:       monthEnd,
	}

	row, err := r.q.GetExpensesSummary(ctx, params)
	if err != nil {
		return nil, fmt.Errorf("expenses summary: %w", err)
	}

	return &models.ExpensesSummary{
		TodayTotal:     row.TodayTotal,
		YesterdayTotal: row.YesterdayTotal,
		MonthTotal:     row.MonthTotal,
	}, nil
}

func (r *ExpenseRepo) GetDailyFinancials(ctx context.Context, startDate, endDate time.Time, timezone string) ([]*models.DailyFinancial, error) {
	params := sqlcdb.GetDailyFinancialsByMonthParams{
		StartDate: startDate,
		EndDate:   endDate,
		Timezone:  timezone,
	}

	rows, err := r.q.GetDailyFinancialsByMonth(ctx, params)
	if err != nil {
		return nil, fmt.Errorf("daily financials: %w", err)
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
