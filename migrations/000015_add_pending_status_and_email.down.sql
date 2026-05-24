DROP INDEX IF EXISTS members_email_unique;
ALTER TABLE members DROP COLUMN IF EXISTS email;

ALTER TABLE members DROP CONSTRAINT IF EXISTS members_status_check;
ALTER TABLE members ADD CONSTRAINT members_status_check
  CHECK (status IN ('active', 'inactive'));
