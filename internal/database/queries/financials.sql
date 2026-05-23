-- name: GetRevenueByPlanType :many
-- Group subscription payments by plan name over a date range
SELECT
    pt.name::text AS plan_name,
    pt.default_price::float8 AS plan_price,
    COALESCE(SUM(p.amount), 0)::float8 AS total_amount,
    COUNT(p.id)::int8 AS transaction_count
FROM payments p
JOIN subscriptions s ON p.subscription_id = s.id
JOIN plan_templates pt ON s.plan_template_id = pt.id
WHERE p.paid_at >= @start_date::timestamptz AND p.paid_at < @end_date::timestamptz
GROUP BY pt.name, pt.default_price
ORDER BY total_amount DESC;

-- name: GetRevenueByPaymentMethod :many
-- Group subscription payments by method over a date range
SELECT
    p.method::text AS payment_method,
    COALESCE(SUM(p.amount), 0)::float8 AS total_amount,
    COUNT(p.id)::int8 AS transaction_count
FROM payments p
WHERE p.paid_at >= @start_date::timestamptz AND p.paid_at < @end_date::timestamptz
GROUP BY p.method
ORDER BY total_amount DESC;

-- name: GetExpensesByCategory :many
-- Group operational costs by category over a date range
SELECT
    e.category::text AS category,
    COALESCE(SUM(e.amount), 0)::float8 AS total_amount,
    COUNT(e.id)::int8 AS expense_count
FROM expenses e
WHERE e.spent_at >= @start_date::timestamptz AND e.spent_at < @end_date::timestamptz
GROUP BY e.category
ORDER BY total_amount DESC;
