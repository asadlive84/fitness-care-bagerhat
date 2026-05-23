-- name: CreateAdmin :one
INSERT INTO admins (id, name, phone, email, password_hash, role, parent_admin_id, created_by_superadmin_id)
VALUES (@id, @name, @phone, @email, @password_hash, @role, @parent_admin_id, @created_by_superadmin_id)
RETURNING *;

-- name: GetAdminByID :one
SELECT * FROM admins WHERE id = @id LIMIT 1;

-- name: GetAdminByEmail :one
SELECT * FROM admins WHERE email = @email LIMIT 1;

-- name: GetAdminByPhone :one
SELECT * FROM admins WHERE phone = @phone LIMIT 1;

-- name: UpdateAdminPassword :exec
UPDATE admins
SET password_hash = @password_hash,
    updated_at    = NOW()
WHERE id = @id;
