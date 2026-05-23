DROP TABLE IF EXISTS ai_token_logs;
DROP TABLE IF EXISTS member_food_logs;
DROP TABLE IF EXISTS ai_prompts;
DROP TABLE IF EXISTS system_settings;

ALTER TABLE members DROP COLUMN IF EXISTS profile_picture_url;
ALTER TABLE members DROP COLUMN IF EXISTS is_ai_allowed;
ALTER TABLE members DROP COLUMN IF EXISTS budget_level;
