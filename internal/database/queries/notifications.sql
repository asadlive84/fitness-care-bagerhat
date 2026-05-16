-- name: CreateNotification :one
INSERT INTO notifications (id, member_id, type, payload, scheduled_at, status)
VALUES (@id, @member_id, @type, @payload, @scheduled_at, @status)
RETURNING *;

-- name: ListPendingNotifications :many
-- Pulled every minute by the scheduler to dispatch overdue notifications.
SELECT * FROM notifications
WHERE status      = 'pending'
  AND scheduled_at <= NOW()
ORDER BY scheduled_at ASC
LIMIT 200;

-- name: UpdateNotificationStatus :exec
UPDATE notifications
SET status  = @status,
    sent_at = CASE WHEN @status::text = 'sent' THEN NOW() ELSE sent_at END
WHERE id    = @id;

-- name: RescheduleNotification :exec
-- Move a notification past the quiet window without changing its status.
UPDATE notifications
SET scheduled_at = @scheduled_at
WHERE id         = @id;
