-- name: CreatePayment :one
INSERT INTO payments (id, member_id, subscription_id, amount, method, paid_at, recorded_by_admin_id)
VALUES (@id, @member_id, @subscription_id, @amount, @method, @paid_at, @recorded_by_admin_id)
RETURNING *;

-- name: ListPaymentsByMember :many
-- Supports optional date range; pass NULL for from_time / to_time to skip filter.
SELECT * FROM payments
WHERE member_id = @member_id
  AND (sqlc.narg('from_time')::timestamptz IS NULL OR paid_at >= sqlc.narg('from_time')::timestamptz)
  AND (sqlc.narg('to_time')::timestamptz IS NULL OR paid_at <= sqlc.narg('to_time')::timestamptz)
ORDER BY paid_at DESC;

-- name: GetPaymentSummaryByMonth :one
SELECT
    COALESCE(SUM(amount), 0)::float8 AS total_amount,
    COUNT(*)                          AS payment_count
FROM payments
WHERE date_trunc('month', paid_at) = date_trunc('month', @month::timestamptz);
