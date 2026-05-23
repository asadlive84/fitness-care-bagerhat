-- name: CreateSubscription :one
INSERT INTO subscriptions (id, member_id, plan_template_id, start_date, end_date, final_price, note, status)
VALUES (@id, @member_id, @plan_template_id, @start_date, @end_date, @final_price, @note, @status)
RETURNING *;

-- name: GetActiveSubscriptionByMemberID :one
SELECT * FROM subscriptions
WHERE member_id = @member_id
  AND status    = 'active'
ORDER BY created_at DESC
LIMIT 1;

-- name: ListSubscriptionsByMemberID :many
SELECT * FROM subscriptions
WHERE member_id = @member_id
ORDER BY created_at DESC;

-- name: UpdateSubscriptionStatus :exec
UPDATE subscriptions
SET status = @status
WHERE id   = @id;

-- name: ReplaceActiveSubscriptions :exec
-- Marks all current active subscriptions for a member as 'replaced' before assigning a new one.
UPDATE subscriptions
SET status = 'replaced'
WHERE member_id = @member_id
  AND status    = 'active';

-- name: UpdateActiveSubscription :one
-- In-place patch of the current active subscription (price, start date, end date, note).
UPDATE subscriptions
SET final_price = @final_price,
    start_date  = @start_date,
    end_date    = @end_date,
    note        = @note
WHERE member_id = @member_id
  AND status    = 'active'
RETURNING *;

-- name: ListExpiringSubscriptions :many
-- Used by the renewal reminder scheduler. Returns active subs ending within their gym's nudge days.
WITH member_nudge_days AS (
    SELECT m.id AS member_id,
           COALESCE(
               (
                   SELECT (s.value->>0)::int
                   FROM settings s
                   WHERE s.key = 'nudge_days'
                     AND (s.admin_id = m.created_by_admin_id OR s.admin_id IS NULL)
                   ORDER BY s.admin_id DESC NULLS LAST
                   LIMIT 1
               ),
               7
           ) AS days
    FROM members m
)
SELECT s.*, m.name AS member_name, m.created_by_admin_id
FROM subscriptions s
JOIN members m ON m.id = s.member_id
JOIN member_nudge_days mnd ON mnd.member_id = m.id
WHERE s.status   = 'active'
  AND s.end_date >= CURRENT_DATE
  AND s.end_date <= CURRENT_DATE + (mnd.days * INTERVAL '1 day')
ORDER BY s.end_date ASC;
