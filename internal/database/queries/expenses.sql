-- name: CreateExpense :one
INSERT INTO expenses (id, amount, description, category, spent_at, recorded_by)
VALUES (@id, @amount, @description, @category, @spent_at, @recorded_by)
RETURNING *;

-- name: ListExpenses :many
SELECT * FROM expenses
WHERE (sqlc.narg('from_time')::timestamptz IS NULL OR spent_at >= sqlc.narg('from_time')::timestamptz)
  AND (sqlc.narg('to_time')::timestamptz IS NULL OR spent_at <= sqlc.narg('to_time')::timestamptz)
ORDER BY spent_at DESC
LIMIT @limit_val::int
OFFSET @offset_val::int;

-- name: CountExpenses :one
SELECT COUNT(*) FROM expenses
WHERE (sqlc.narg('from_time')::timestamptz IS NULL OR spent_at >= sqlc.narg('from_time')::timestamptz)
  AND (sqlc.narg('to_time')::timestamptz IS NULL OR spent_at <= sqlc.narg('to_time')::timestamptz);

-- name: GetExpensesSummary :one
SELECT
    COALESCE(SUM(CASE WHEN spent_at >= @today_start::timestamptz AND spent_at < @today_end::timestamptz THEN amount ELSE 0 END), 0)::float8 AS today_total,
    COALESCE(SUM(CASE WHEN spent_at >= @yesterday_start::timestamptz AND spent_at < @yesterday_end::timestamptz THEN amount ELSE 0 END), 0)::float8 AS yesterday_total,
    COALESCE(SUM(CASE WHEN spent_at >= @month_start::timestamptz AND spent_at < @month_end::timestamptz THEN amount ELSE 0 END), 0)::float8 AS month_total
FROM expenses;

-- name: GetDailyFinancialsByMonth :many
WITH daily_payments AS (
    SELECT
        (paid_at AT TIME ZONE @timezone::text)::date AS trans_date,
        COALESCE(SUM(amount), 0)::float8 AS total_earnings
    FROM payments
    WHERE paid_at >= @start_date::timestamptz AND paid_at < @end_date::timestamptz
    GROUP BY 1
),
daily_expenses AS (
    SELECT
        (spent_at AT TIME ZONE @timezone::text)::date AS trans_date,
        COALESCE(SUM(amount), 0)::float8 AS total_expenses
    FROM expenses
    WHERE spent_at >= @start_date::timestamptz AND spent_at < @end_date::timestamptz
    GROUP BY 1
),
all_dates AS (
    SELECT trans_date FROM daily_payments
    UNION
    SELECT trans_date FROM daily_expenses
)
SELECT
    all_dates.trans_date AS date,
    COALESCE(p.total_earnings, 0)::float8 AS earnings,
    COALESCE(e.total_expenses, 0)::float8 AS expenses,
    (COALESCE(p.total_earnings, 0) - COALESCE(e.total_expenses, 0))::float8 AS net
FROM all_dates
LEFT JOIN daily_payments p ON all_dates.trans_date = p.trans_date
LEFT JOIN daily_expenses e ON all_dates.trans_date = e.trans_date
ORDER BY all_dates.trans_date ASC;
