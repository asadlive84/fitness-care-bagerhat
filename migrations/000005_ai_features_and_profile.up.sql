-- Update members table
ALTER TABLE members ADD COLUMN budget_level TEXT;
ALTER TABLE members ADD COLUMN is_ai_allowed BOOLEAN NOT NULL DEFAULT TRUE;
ALTER TABLE members ADD COLUMN profile_picture_url TEXT;

-- Create system_settings table
CREATE TABLE system_settings (
    setting_key   TEXT PRIMARY KEY,
    setting_value TEXT NOT NULL,
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Insert default settings
INSERT INTO system_settings (setting_key, setting_value) VALUES 
('max_daily_food_uploads', '5'),
('is_global_ai_enabled', 'true');

-- Create ai_prompts table
CREATE TABLE ai_prompts (
    id           SERIAL PRIMARY KEY,
    prompt_type  TEXT UNIQUE NOT NULL,
    prompt_text  TEXT NOT NULL,
    is_active    BOOLEAN NOT NULL DEFAULT TRUE,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create member_food_logs table
CREATE TABLE member_food_logs (
    id               BIGSERIAL PRIMARY KEY,
    member_id        UUID NOT NULL REFERENCES members(id) ON DELETE CASCADE,
    image_url        TEXT NOT NULL,
    device_model     TEXT,
    capture_time     TIMESTAMPTZ,
    ai_response_json JSONB,
    log_date         DATE NOT NULL DEFAULT CURRENT_DATE,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create ai_token_logs table
CREATE TABLE ai_token_logs (
    id                BIGSERIAL PRIMARY KEY,
    member_id         UUID NOT NULL REFERENCES members(id) ON DELETE CASCADE,
    feature_used      TEXT NOT NULL,
    prompt_tokens     INTEGER NOT NULL DEFAULT 0,
    completion_tokens INTEGER NOT NULL DEFAULT 0,
    total_tokens      INTEGER NOT NULL DEFAULT 0,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
