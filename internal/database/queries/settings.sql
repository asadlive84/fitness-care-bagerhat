-- name: GetAllSettings :many
SELECT * FROM settings ORDER BY key;

-- name: GetSettingByKey :one
SELECT * FROM settings WHERE key = @key LIMIT 1;

-- name: UpsertSetting :one
INSERT INTO settings (key, value, updated_at)
VALUES (@key, @value, NOW())
ON CONFLICT (key)
DO UPDATE SET
    value      = EXCLUDED.value,
    updated_at = NOW()
RETURNING *;
