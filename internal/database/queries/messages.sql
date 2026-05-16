-- name: CreateMessage :one
INSERT INTO messages (id, sender_id, sender_role, receiver_id, is_broadcast, broadcast_filter, content, sent_at)
VALUES (@id, @sender_id, @sender_role, @receiver_id, @is_broadcast, @broadcast_filter, @content, @sent_at)
RETURNING *;

-- name: ListDirectMessagesByMember :many
-- Returns the direct conversation between admin and a specific member.
SELECT * FROM messages
WHERE is_broadcast = FALSE
  AND (
      (sender_role = 'member' AND sender_id   = @member_id)
   OR (sender_role = 'admin'  AND receiver_id = @member_id)
  )
ORDER BY sent_at ASC;

-- name: GetLatestDirectMessageByMember :one
-- Used to build the conversation summary list.
SELECT * FROM messages
WHERE is_broadcast = FALSE
  AND (
      (sender_role = 'member' AND sender_id   = @member_id)
   OR (sender_role = 'admin'  AND receiver_id = @member_id)
  )
ORDER BY sent_at DESC
LIMIT 1;

-- name: ListConversationMemberIDs :many
-- Returns one row per member who has exchanged a direct message with admin.
SELECT DISTINCT
    CASE
        WHEN sender_role = 'member' THEN sender_id
        ELSE receiver_id
    END AS member_id
FROM messages
WHERE is_broadcast = FALSE
ORDER BY member_id;

-- name: ListBroadcasts :many
SELECT * FROM messages
WHERE is_broadcast = TRUE
ORDER BY sent_at DESC
LIMIT  sqlc.arg('limit_count')::int
OFFSET sqlc.arg('offset_count')::int;

-- name: ListMemberMessages :many
-- All messages relevant to a member: direct (both directions) + all broadcasts.
SELECT * FROM messages
WHERE (
    (is_broadcast = FALSE AND (
        (sender_role = 'member' AND sender_id   = @member_id)
     OR (sender_role = 'admin'  AND receiver_id = @member_id)
    ))
    OR is_broadcast = TRUE
)
ORDER BY sent_at DESC
LIMIT  sqlc.arg('limit_count')::int
OFFSET sqlc.arg('offset_count')::int;

-- name: MarkMemberMessagesAsRead :exec
-- Admin opens a conversation: mark unread member→admin messages as read.
UPDATE messages
SET read_at = NOW()
WHERE sender_role  = 'member'
  AND sender_id    = @member_id
  AND is_broadcast = FALSE
  AND read_at IS NULL;

-- name: MarkAdminMessagesAsRead :exec
-- Member opens their inbox: mark unread admin→member messages as read.
UPDATE messages
SET read_at = NOW()
WHERE sender_role  = 'admin'
  AND receiver_id  = @member_id
  AND is_broadcast = FALSE
  AND read_at IS NULL;
