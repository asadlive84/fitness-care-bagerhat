-- name: RecordProfilePictureUpdate :one
INSERT INTO profile_picture_updates (member_id, updated_by_role, updated_by_id)
VALUES ($1, $2, $3)
RETURNING *;

-- name: CountProfilePictureUpdates :one
SELECT COUNT(*)
FROM profile_picture_updates
WHERE member_id = $1 AND updated_by_role = $2;
