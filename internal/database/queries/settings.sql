-- name: GetAllSettings :many
WITH admin_settings AS (
    SELECT key, value, updated_at, admin_id,
           ROW_NUMBER() OVER (PARTITION BY key ORDER BY admin_id DESC NULLS LAST) as rn
    FROM settings
    WHERE admin_id = $1 OR admin_id IS NULL
)
SELECT key, value, updated_at, admin_id
FROM admin_settings
WHERE rn = 1
ORDER BY key;

-- name: GetSettingByKey :one
SELECT * FROM settings
WHERE key = $1 AND (admin_id = $2 OR admin_id IS NULL)
ORDER BY admin_id DESC NULLS LAST
LIMIT 1;

-- name: UpsertSettingGlobal :one
INSERT INTO settings (key, value, admin_id, updated_at)
VALUES ($1, $2, NULL, NOW())
ON CONFLICT (key) WHERE admin_id IS NULL DO UPDATE SET
    value      = EXCLUDED.value,
    updated_at = NOW()
RETURNING *;

-- name: UpsertSettingTenant :one
INSERT INTO settings (key, value, admin_id, updated_at)
VALUES ($1, $2, $3, NOW())
ON CONFLICT (key, admin_id) WHERE admin_id IS NOT NULL DO UPDATE SET
    value      = EXCLUDED.value,
    updated_at = NOW()
RETURNING *;
