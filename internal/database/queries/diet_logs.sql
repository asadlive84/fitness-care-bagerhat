-- name: CreateDietLog :one
INSERT INTO diet_logs (id, member_id, content, logged_at)
VALUES (@id, @member_id, @content, @logged_at)
RETURNING *;

-- name: ListDietLogsByMemberID :many
SELECT * FROM diet_logs
WHERE member_id = @member_id
ORDER BY logged_at DESC
LIMIT  sqlc.arg('limit_count')::int
OFFSET sqlc.arg('offset_count')::int;
