-- Drop the unique partial indexes
DROP INDEX IF EXISTS settings_tenant_idx;
DROP INDEX IF EXISTS settings_global_idx;

-- Clean up any tenant-specific override settings
DELETE FROM settings WHERE admin_id IS NOT NULL;

-- Drop admin_id column
ALTER TABLE settings DROP COLUMN IF EXISTS admin_id;

-- Restore the primary key constraint on key
ALTER TABLE settings ADD CONSTRAINT settings_pkey PRIMARY KEY (key);

-- Restore defaults to TRUE
ALTER TABLE members ALTER COLUMN is_ai_allowed SET DEFAULT TRUE;
ALTER TABLE members ALTER COLUMN is_ai_food_log_allowed SET DEFAULT TRUE;

-- Update existing members to TRUE
UPDATE members SET is_ai_allowed = TRUE, is_ai_food_log_allowed = TRUE;
