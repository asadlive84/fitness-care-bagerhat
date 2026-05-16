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
-- Active members who have not logged weight in the last @days days.
SELECT m.*
FROM members m
WHERE m.status = 'active'
  AND NOT EXISTS (
      SELECT 1
      FROM weight_logs wl
      WHERE wl.member_id = m.id
        AND wl.logged_at >= NOW() - (sqlc.arg('days')::int * INTERVAL '1 day')
  );
