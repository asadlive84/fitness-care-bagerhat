-- name: UpsertFCMToken :one
INSERT INTO fcm_tokens (id, member_id, token, device_info, last_active_at)
VALUES (@id, @member_id, @token, @device_info, NOW())
ON CONFLICT (token)
DO UPDATE SET
    member_id      = EXCLUDED.member_id,
    device_info    = EXCLUDED.device_info,
    last_active_at = NOW()
RETURNING *;

-- name: ListFCMTokensByMemberID :many
SELECT * FROM fcm_tokens
WHERE member_id = @member_id
ORDER BY last_active_at DESC;

-- name: DeleteFCMTokensByMemberID :exec
DELETE FROM fcm_tokens WHERE member_id = @member_id;

-- name: DeleteFCMToken :exec
DELETE FROM fcm_tokens WHERE token = @token;
