-- name: CreateWeightLog :one
INSERT INTO weight_logs (id, member_id, weight_kg, logged_at)
VALUES (@id, @member_id, @weight_kg, @logged_at)
RETURNING *;

-- name: ListWeightLogsByMember :many
-- Optional date range: pass NULL for from_time / to_time to skip that bound.
SELECT * FROM weight_logs
WHERE member_id = @member_id
  AND (sqlc.narg('from_time')::timestamptz IS NULL OR logged_at >= sqlc.narg('from_time')::timestamptz)
  AND (sqlc.narg('to_time')::timestamptz IS NULL OR logged_at <  sqlc.narg('to_time')::timestamptz)
ORDER BY logged_at DESC;

-- name: GetLatestWeightLogByMemberID :one
SELECT * FROM weight_logs
WHERE member_id = @member_id
ORDER BY logged_at DESC
LIMIT 1;

-- name: ListMembersNeedingWeightReminder :many
-- Active members who have not logged weight in their gym's weight reminder days.
WITH member_reminder_days AS (
    SELECT m.id AS member_id,
           COALESCE(
               (
                   SELECT (s.value->>0)::int
                   FROM settings s
                   WHERE s.key = 'weight_reminder_days'
                     AND (s.admin_id = m.created_by_admin_id OR s.admin_id IS NULL)
                   ORDER BY s.admin_id DESC NULLS LAST
                   LIMIT 1
               ),
               7
           ) AS days
    FROM members m
)
SELECT m.*
FROM members m
JOIN member_reminder_days mrd ON mrd.member_id = m.id
WHERE m.status = 'active'
  AND NOT EXISTS (
      SELECT 1
      FROM weight_logs wl
      WHERE wl.member_id = m.id
        AND wl.logged_at >= NOW() - (mrd.days * INTERVAL '1 day')
  );
