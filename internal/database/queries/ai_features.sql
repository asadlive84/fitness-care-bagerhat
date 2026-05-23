-- name: GetSystemSetting :one
SELECT * FROM system_settings 
WHERE setting_key = $1 AND (admin_id = $2 OR admin_id IS NULL)
ORDER BY admin_id DESC NULLS LAST
LIMIT 1;

-- name: UpdateSystemSetting :exec
INSERT INTO system_settings (setting_key, setting_value, admin_id, updated_at)
VALUES ($1, $2, $3, NOW())
ON CONFLICT (setting_key, admin_id) DO UPDATE SET setting_value = $2, updated_at = NOW();

-- name: GetAIPrompt :one
SELECT * FROM ai_prompts 
WHERE prompt_type = $1 AND is_active = TRUE AND (admin_id = $2 OR admin_id IS NULL)
ORDER BY admin_id DESC NULLS LAST
LIMIT 1;

-- name: UpdateAIPromptGlobal :exec
INSERT INTO ai_prompts (prompt_type, prompt_text, is_active, admin_id, updated_at)
VALUES ($1, $2, $3, NULL, NOW())
ON CONFLICT (prompt_type) WHERE admin_id IS NULL
DO UPDATE SET prompt_text = EXCLUDED.prompt_text, is_active = EXCLUDED.is_active, updated_at = NOW();

-- name: UpdateAIPromptTenant :exec
INSERT INTO ai_prompts (prompt_type, prompt_text, is_active, admin_id, updated_at)
VALUES ($1, $2, $3, $4, NOW())
ON CONFLICT (prompt_type, admin_id) WHERE admin_id IS NOT NULL
DO UPDATE SET prompt_text = EXCLUDED.prompt_text, is_active = EXCLUDED.is_active, updated_at = NOW();

-- name: ListAIPrompts :many
SELECT * FROM ai_prompts ORDER BY prompt_type ASC;

-- name: CreateMemberFoodLog :one
INSERT INTO member_food_logs (
    member_id, image_url, device_model, capture_time, ai_response_json, log_date
) VALUES (
    $1, $2, $3, $4, $5, $6
) RETURNING *;

-- name: CountDailyFoodUploads :one
SELECT COUNT(*) FROM member_food_logs WHERE member_id = $1 AND log_date = $2;

-- name: LogAITokenUsage :one
INSERT INTO ai_token_logs (
    member_id, feature_used, prompt_tokens, completion_tokens, total_tokens
) VALUES (
    $1, $2, $3, $4, $5
) RETURNING *;

-- name: ListMemberFoodLogs :many
SELECT * FROM member_food_logs WHERE member_id = $1 ORDER BY created_at DESC LIMIT $2 OFFSET $3;

-- name: UpdateMemberAIProfile :one
UPDATE members
SET budget_level = $2, is_ai_allowed = $3, is_ai_food_log_allowed = $4, profile_picture_url = $5, updated_at = NOW()
WHERE id = $1
RETURNING *;

-- name: LogAIAuditUsage :one
INSERT INTO superadmin_ai_audit_logs (
    member_id, admin_id, prompt_type, prompt_text, ai_response_json, 
    prompt_tokens, completion_tokens, total_tokens, estimated_cost
) VALUES (
    $1, $2, $3, $4, $5, $6, $7, $8, $9
) RETURNING *;

-- name: GetAITokenUsagePerUser :many
-- Returns AI token usage and cost per member
SELECT
    m.id AS member_id,
    m.name AS member_name,
    m.phone AS member_phone,
    m.created_by_admin_id,
    COALESCE(SUM(l.prompt_tokens), 0)::int8 AS total_prompt_tokens,
    COALESCE(SUM(l.completion_tokens), 0)::int8 AS total_completion_tokens,
    COALESCE(SUM(l.total_tokens), 0)::int8 AS total_tokens,
    COALESCE(SUM(l.estimated_cost), 0.000000)::numeric(10, 6) AS total_estimated_cost
FROM members m
LEFT JOIN superadmin_ai_audit_logs l ON l.member_id = m.id
GROUP BY m.id, m.name, m.phone, m.created_by_admin_id
ORDER BY total_estimated_cost DESC;

-- name: GetAITokenUsageForUser :one
-- Returns AI token usage and cost for a single member
SELECT
    m.id AS member_id,
    m.name AS member_name,
    COALESCE(SUM(l.prompt_tokens), 0)::int8 AS total_prompt_tokens,
    COALESCE(SUM(l.completion_tokens), 0)::int8 AS total_completion_tokens,
    COALESCE(SUM(l.total_tokens), 0)::int8 AS total_tokens,
    COALESCE(SUM(l.estimated_cost), 0.000000)::numeric(10, 6) AS total_estimated_cost
FROM members m
LEFT JOIN superadmin_ai_audit_logs l ON l.member_id = m.id
WHERE m.id = $1
GROUP BY m.id, m.name;

-- name: GetAITokenUsagePerAdmin :many
-- Returns AI token usage and cost per Gym Admin
SELECT
    a.id AS admin_id,
    a.name AS admin_name,
    a.email AS admin_email,
    COALESCE(SUM(l.prompt_tokens), 0)::int8 AS total_prompt_tokens,
    COALESCE(SUM(l.completion_tokens), 0)::int8 AS total_completion_tokens,
    COALESCE(SUM(l.total_tokens), 0)::int8 AS total_tokens,
    COALESCE(SUM(l.estimated_cost), 0.000000)::numeric(10, 6) AS total_estimated_cost
FROM admins a
LEFT JOIN superadmin_ai_audit_logs l ON l.admin_id = a.id
GROUP BY a.id, a.name, a.email
ORDER BY total_estimated_cost DESC;

-- name: ListAIAuditLogs :many
SELECT * FROM superadmin_ai_audit_logs
WHERE (sqlc.narg('admin_id')::uuid IS NULL OR admin_id = sqlc.narg('admin_id')::uuid)
  AND (sqlc.narg('member_id')::uuid IS NULL OR member_id = sqlc.narg('member_id')::uuid)
  AND (sqlc.narg('prompt_type')::text IS NULL OR prompt_type = sqlc.narg('prompt_type')::text)
  AND (sqlc.narg('from_time')::timestamptz IS NULL OR created_at >= sqlc.narg('from_time')::timestamptz)
  AND (sqlc.narg('to_time')::timestamptz IS NULL OR created_at <= sqlc.narg('to_time')::timestamptz)
ORDER BY created_at DESC
LIMIT @limit_count::int
OFFSET @offset_count::int;

-- name: CountAIAuditLogs :one
SELECT COUNT(*) FROM superadmin_ai_audit_logs
WHERE (sqlc.narg('admin_id')::uuid IS NULL OR admin_id = sqlc.narg('admin_id')::uuid)
  AND (sqlc.narg('member_id')::uuid IS NULL OR member_id = sqlc.narg('member_id')::uuid)
  AND (sqlc.narg('prompt_type')::text IS NULL OR prompt_type = sqlc.narg('prompt_type')::text)
  AND (sqlc.narg('from_time')::timestamptz IS NULL OR created_at >= sqlc.narg('from_time')::timestamptz)
  AND (sqlc.narg('to_time')::timestamptz IS NULL OR created_at <= sqlc.narg('to_time')::timestamptz);

-- name: AICostByGym :many
SELECT
    a.id AS admin_id,
    a.name AS admin_name,
    COUNT(l.id)::int8 AS total_executions,
    COALESCE(SUM(l.total_tokens), 0)::int8 AS total_tokens,
    COALESCE(SUM(l.estimated_cost), 0.000000)::numeric(10, 6) AS total_cost
FROM admins a
LEFT JOIN superadmin_ai_audit_logs l ON l.admin_id = a.id
WHERE (sqlc.narg('from_time')::timestamptz IS NULL OR l.created_at >= sqlc.narg('from_time')::timestamptz)
  AND (sqlc.narg('to_time')::timestamptz IS NULL OR l.created_at <= sqlc.narg('to_time')::timestamptz)
GROUP BY a.id, a.name
ORDER BY total_cost DESC;

-- name: AIHeavyUsers :many
SELECT
    m.id AS member_id,
    m.name AS member_name,
    a.id AS admin_id,
    a.name AS admin_name,
    COUNT(l.id)::int8 AS total_calls,
    COALESCE(SUM(l.total_tokens), 0)::int8 AS total_tokens,
    COALESCE(SUM(l.estimated_cost), 0.000000)::numeric(10, 6) AS total_cost
FROM members m
JOIN admins a ON m.created_by_admin_id = a.id
JOIN superadmin_ai_audit_logs l ON l.member_id = m.id
WHERE (sqlc.narg('from_time')::timestamptz IS NULL OR l.created_at >= sqlc.narg('from_time')::timestamptz)
  AND (sqlc.narg('to_time')::timestamptz IS NULL OR l.created_at <= sqlc.narg('to_time')::timestamptz)
GROUP BY m.id, m.name, a.id, a.name
HAVING COALESCE(SUM(l.total_tokens), 0)::int8 >= @threshold::int8
ORDER BY total_tokens DESC
LIMIT @limit_count::int;

-- name: CountDietChartsGenerated :one
SELECT COUNT(*) FROM superadmin_ai_audit_logs
WHERE member_id = $1 AND prompt_type = 'diet_chart';


