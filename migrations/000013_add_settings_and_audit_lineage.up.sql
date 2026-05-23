-- 1. system_settings table updates
ALTER TABLE system_settings DROP CONSTRAINT IF EXISTS system_settings_pkey;
ALTER TABLE system_settings ADD COLUMN IF NOT EXISTS admin_id UUID REFERENCES admins(id) ON DELETE CASCADE;
CREATE UNIQUE INDEX IF NOT EXISTS system_settings_global_idx ON system_settings (setting_key) WHERE admin_id IS NULL;
CREATE UNIQUE INDEX IF NOT EXISTS system_settings_tenant_idx ON system_settings (setting_key, admin_id) WHERE admin_id IS NOT NULL;

-- 2. ai_prompts table updates
ALTER TABLE ai_prompts DROP CONSTRAINT IF EXISTS ai_prompts_prompt_type_key;
ALTER TABLE ai_prompts ADD COLUMN IF NOT EXISTS admin_id UUID REFERENCES admins(id) ON DELETE CASCADE;
CREATE UNIQUE INDEX IF NOT EXISTS ai_prompts_global_idx ON ai_prompts (prompt_type) WHERE admin_id IS NULL;
CREATE UNIQUE INDEX IF NOT EXISTS ai_prompts_tenant_idx ON ai_prompts (prompt_type, admin_id) WHERE admin_id IS NOT NULL;

-- 3. Create superadmin_ai_audit_logs table
CREATE TABLE IF NOT EXISTS superadmin_ai_audit_logs (
    id                BIGSERIAL PRIMARY KEY,
    member_id         UUID NOT NULL REFERENCES members(id) ON DELETE CASCADE,
    admin_id          UUID NOT NULL REFERENCES admins(id) ON DELETE CASCADE,
    prompt_type       TEXT NOT NULL,
    prompt_text       TEXT NOT NULL,
    ai_response_json  JSONB NOT NULL,
    prompt_tokens     INTEGER NOT NULL DEFAULT 0,
    completion_tokens INTEGER NOT NULL DEFAULT 0,
    total_tokens      INTEGER NOT NULL DEFAULT 0,
    estimated_cost    NUMERIC(10, 6) NOT NULL DEFAULT 0.000000,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
