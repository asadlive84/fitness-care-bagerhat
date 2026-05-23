ALTER TABLE members DROP COLUMN IF EXISTS created_by_admin_id;
ALTER TABLE admins DROP COLUMN IF EXISTS created_by_superadmin_id;
ALTER TABLE admins DROP COLUMN IF EXISTS parent_admin_id;
