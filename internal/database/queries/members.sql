-- name: CreateMember :one
INSERT INTO members (id, name, phone, password_hash, gender, goal, join_date, current_weight, status, must_change_password)
VALUES (@id, @name, @phone, @password_hash, @gender, @goal, @join_date, @current_weight, @status, @must_change_password)
RETURNING *;

-- name: GetMemberByID :one
SELECT * FROM members WHERE id = @id LIMIT 1;

-- name: GetMemberByPhone :one
SELECT * FROM members WHERE phone = @phone LIMIT 1;

-- name: ListMembers :many
SELECT * FROM members
WHERE
    (sqlc.narg('status')::text IS NULL OR status = sqlc.narg('status')::text)
    AND (
        sqlc.narg('search')::text IS NULL
        OR name  ILIKE '%' || sqlc.narg('search')::text || '%'
        OR phone ILIKE '%' || sqlc.narg('search')::text || '%'
    )
ORDER BY created_at DESC
LIMIT  sqlc.arg('limit_count')::int
OFFSET sqlc.arg('offset_count')::int;

-- name: CountMembers :one
SELECT COUNT(*) FROM members
WHERE
    (sqlc.narg('status')::text IS NULL OR status = sqlc.narg('status')::text)
    AND (
        sqlc.narg('search')::text IS NULL
        OR name  ILIKE '%' || sqlc.narg('search')::text || '%'
        OR phone ILIKE '%' || sqlc.narg('search')::text || '%'
    );

-- name: UpdateMember :one
UPDATE members
SET name           = @name,
    phone          = @phone,
    gender         = @gender,
    goal           = @goal,
    current_weight = @current_weight,
    updated_at     = NOW()
WHERE id = @id
RETURNING *;

-- name: UpdateMemberStatus :exec
UPDATE members
SET status     = @status,
    updated_at = NOW()
WHERE id = @id;

-- name: UpdateMemberPassword :exec
UPDATE members
SET password_hash        = @password_hash,
    must_change_password = FALSE,
    updated_at           = NOW()
WHERE id = @id;

-- name: ListMembersWithExpiringSoon :many
-- Returns active members whose active subscription ends within @days days.
SELECT DISTINCT m.*
FROM members m
JOIN subscriptions s ON s.member_id = m.id
WHERE m.status     = 'active'
  AND s.status     = 'active'
  AND s.end_date   >= CURRENT_DATE
  AND s.end_date   <= CURRENT_DATE + (sqlc.arg('days')::int * INTERVAL '1 day')
ORDER BY m.created_at DESC;
