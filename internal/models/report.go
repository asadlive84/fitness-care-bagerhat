package models

import "time"

// PlanRevenueBreakdown holds aggregated revenue for a specific membership plan.
type PlanRevenueBreakdown struct {
	PlanName         string  `json:"plan_name"`
	PlanPrice        float64 `json:"plan_price"`
	TotalAmount      float64 `json:"total_amount"`
	TransactionCount int64   `json:"transaction_count"`
}

// MethodRevenueBreakdown holds aggregated revenue for a specific payment method.
type MethodRevenueBreakdown struct {
	PaymentMethod    string  `json:"payment_method"`
	TotalAmount      float64 `json:"total_amount"`
	TransactionCount int64   `json:"transaction_count"`
}

// CategoryExpenseBreakdown holds aggregated costs for a specific operational category.
type CategoryExpenseBreakdown struct {
	Category     string  `json:"category"`
	TotalAmount  float64 `json:"total_amount"`
	ExpenseCount int64   `json:"expense_count"`
}

// FinancialsReport is the single centralized payload representing the gym's complete finances over a custom date range.
type FinancialsReport struct {
	StartDate          time.Time                 `json:"start_date"`
	EndDate            time.Time                 `json:"end_date"`
	TotalIncome        float64                   `json:"total_income"`
	TotalCost          float64                   `json:"total_cost"`
	NetProfit          float64                   `json:"net_profit"`
	Timeline           []*DailyFinancial         `json:"timeline"`
	RevenueByPlan      []*PlanRevenueBreakdown   `json:"revenue_by_plan"`
	RevenueByMethod    []*MethodRevenueBreakdown `json:"revenue_by_method"`
	ExpensesByCategory []*CategoryExpenseBreakdown `json:"expenses_by_category"`
}
