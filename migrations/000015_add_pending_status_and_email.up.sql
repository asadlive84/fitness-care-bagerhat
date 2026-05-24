-- Extend status to support self-registration workflow
ALTER TABLE members DROP CONSTRAINT IF EXISTS members_status_check;
ALTER TABLE members ADD CONSTRAINT members_status_check
  CHECK (status IN ('active', 'inactive', 'pending', 'rejected'));

-- Email for self-registered members (nullable; existing admin-created members may not have one)
ALTER TABLE members ADD COLUMN IF NOT EXISTS email VARCHAR(255);
CREATE UNIQUE INDEX IF NOT EXISTS members_email_unique ON members (email) WHERE email IS NOT NULL;
