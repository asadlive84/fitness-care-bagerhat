ALTER TABLE members
  DROP COLUMN IF EXISTS height_cm,
  DROP COLUMN IF EXISTS date_of_birth,
  DROP COLUMN IF EXISTS religion,
  DROP COLUMN IF EXISTS blood_group,
  DROP COLUMN IF EXISTS hobbies,
  DROP COLUMN IF EXISTS present_address,
  DROP COLUMN IF EXISTS permanent_address,
  DROP COLUMN IF EXISTS occupation,
  DROP COLUMN IF EXISTS nid,
  DROP COLUMN IF EXISTS emergency_phone;
