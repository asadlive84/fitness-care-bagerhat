-- Extend the members table with full profile fields.
-- All columns are nullable so existing rows are not affected.

ALTER TABLE members
  ADD COLUMN IF NOT EXISTS height_cm         NUMERIC(5,2),
  ADD COLUMN IF NOT EXISTS date_of_birth     DATE,
  ADD COLUMN IF NOT EXISTS religion          VARCHAR(50),
  ADD COLUMN IF NOT EXISTS blood_group       VARCHAR(5),
  ADD COLUMN IF NOT EXISTS hobbies           TEXT[],
  ADD COLUMN IF NOT EXISTS present_address   TEXT,
  ADD COLUMN IF NOT EXISTS permanent_address TEXT,
  ADD COLUMN IF NOT EXISTS occupation        VARCHAR(100),
  ADD COLUMN IF NOT EXISTS nid               VARCHAR(50),
  ADD COLUMN IF NOT EXISTS emergency_phone   VARCHAR(15);
