-- Drop superadmin_ai_audit_logs table
DROP TABLE IF EXISTS superadmin_ai_audit_logs;

-- Rollback ai_prompts updates
DROP INDEX IF EXISTS ai_prompts_tenant_idx;
DROP INDEX IF EXISTS ai_prompts_global_idx;
ALTER TABLE ai_prompts DROP COLUMN IF EXISTS admin_id;
ALTER TABLE ai_prompts ADD CONSTRAINT ai_prompts_prompt_type_key UNIQUE (prompt_type);

-- Rollback system_settings updates
DROP INDEX IF EXISTS system_settings_tenant_idx;
DROP INDEX IF EXISTS system_settings_global_idx;
ALTER TABLE system_settings DROP COLUMN IF EXISTS admin_id;
ALTER TABLE system_settings ADD CONSTRAINT system_settings_pkey PRIMARY KEY (setting_key);
