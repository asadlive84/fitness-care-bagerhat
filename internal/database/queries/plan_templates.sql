-- name: CreatePlanTemplate :one
INSERT INTO plan_templates (id, name, duration_days, default_price)
VALUES (@id, @name, @duration_days, @default_price)
RETURNING *;

-- name: GetPlanTemplateByID :one
SELECT * FROM plan_templates WHERE id = @id LIMIT 1;

-- name: ListPlanTemplates :many
SELECT * FROM plan_templates ORDER BY created_at DESC;

-- name: UpdatePlanTemplate :one
UPDATE plan_templates
SET name          = @name,
    duration_days = @duration_days,
    default_price = @default_price,
    updated_at    = NOW()
WHERE id = @id
RETURNING *;

-- name: DeletePlanTemplate :exec
DELETE FROM plan_templates WHERE id = @id;
