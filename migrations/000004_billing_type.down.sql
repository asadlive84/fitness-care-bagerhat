ALTER TABLE subscriptions
  DROP COLUMN IF EXISTS postpaid_grace_after,
  DROP COLUMN IF EXISTS postpaid_grace_before,
  DROP COLUMN IF EXISTS prepaid_due_date,
  DROP COLUMN IF EXISTS billing_type;

ALTER TABLE plan_templates
  DROP COLUMN IF EXISTS billing_type;
