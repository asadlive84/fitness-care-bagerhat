-- ── 1. Settings Table Refactoring ──────────────────────────────────────────
-- Drop the primary key constraint on settings
ALTER TABLE settings DROP CONSTRAINT IF EXISTS settings_pkey;

-- Add admin_id column referencing admins
ALTER TABLE settings ADD COLUMN IF NOT EXISTS admin_id UUID REFERENCES admins(id) ON DELETE CASCADE;

-- Create unique partial indexes to support nullable composite keys
CREATE UNIQUE INDEX IF NOT EXISTS settings_global_idx ON settings (key) WHERE admin_id IS NULL;
CREATE UNIQUE INDEX IF NOT EXISTS settings_tenant_idx ON settings (key, admin_id) WHERE admin_id IS NOT NULL;

-- ── 2. Members AI Columns Refactoring (Disabled by Default) ────────────────
-- Alter columns to default to FALSE
ALTER TABLE members ALTER COLUMN is_ai_allowed SET DEFAULT FALSE;
ALTER TABLE members ALTER COLUMN is_ai_food_log_allowed SET DEFAULT FALSE;

-- Set existing members to FALSE (turn feature off by default)
UPDATE members SET is_ai_allowed = FALSE, is_ai_food_log_allowed = FALSE;
