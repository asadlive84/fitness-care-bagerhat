package models

import (
	"time"

	"github.com/google/uuid"
)

// Expense represents a logged operational gym expense.
type Expense struct {
	ID          uuid.UUID `json:"id"`
	Amount      float64   `json:"amount"`
	Description string    `json:"description"`
	Category    string    `json:"category"` // 'Water', 'Bill', 'Salary', 'Rent', 'Maintenance', 'Others'
	SpentAt     time.Time `json:"spent_at"`
	RecordedBy  uuid.UUID `json:"recorded_by"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
}

// ExpensesSummary holds operational expense aggregates.
type ExpensesSummary struct {
	TodayTotal     float64 `json:"today_total"`
	YesterdayTotal float64 `json:"yesterday_total"`
	MonthTotal     float64 `json:"month_total"`
}

// DailyFinancial represents aggregated daily financials for calendar ledger.
type DailyFinancial struct {
	Date     time.Time `json:"date"`
	Earnings float64   `json:"earnings"`
	Expenses float64   `json:"expenses"`
	Net      float64   `json:"net"`
}

// ListExpensesFilter supports date-range filtering and pagination.
type ListExpensesFilter struct {
	From  *time.Time `json:"from"`
	To    *time.Time `json:"to"`
	Limit int        `json:"limit"`
	Page  int        `json:"page"`
}
