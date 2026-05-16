-- Drop in reverse FK order so constraints are never violated.
DROP TABLE IF EXISTS system_logs   CASCADE;
DROP TABLE IF EXISTS settings      CASCADE;
DROP TABLE IF EXISTS fcm_tokens    CASCADE;
DROP TABLE IF EXISTS notifications CASCADE;
DROP TABLE IF EXISTS messages      CASCADE;
DROP TABLE IF EXISTS diet_logs     CASCADE;
DROP TABLE IF EXISTS workout_logs  CASCADE;
DROP TABLE IF EXISTS weight_logs   CASCADE;
DROP TABLE IF EXISTS payments      CASCADE;
DROP TABLE IF EXISTS subscriptions CASCADE;
DROP TABLE IF EXISTS plan_templates CASCADE;
DROP TABLE IF EXISTS members       CASCADE;
DROP TABLE IF EXISTS admins        CASCADE;
