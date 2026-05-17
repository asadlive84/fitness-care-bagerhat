-- Add billing_type to plan_templates (default 'prepaid')
ALTER TABLE plan_templates
  ADD COLUMN billing_type TEXT NOT NULL DEFAULT 'prepaid'
  CONSTRAINT plan_templates_billing_type_check CHECK (billing_type IN ('prepaid', 'postpaid'));

-- Add billing fields to subscriptions
ALTER TABLE subscriptions
  ADD COLUMN billing_type         TEXT NOT NULL DEFAULT 'prepaid'
    CONSTRAINT subscriptions_billing_type_check CHECK (billing_type IN ('prepaid', 'postpaid')),
  ADD COLUMN prepaid_due_date     DATE,
  ADD COLUMN postpaid_grace_before INT  NOT NULL DEFAULT 5,
  ADD COLUMN postpaid_grace_after  INT  NOT NULL DEFAULT 5;
