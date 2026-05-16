-- gen_random_uuid() is built-in since PostgreSQL 13; no extension needed on PG 15.

-- ── admins ───────────────────────────────────────────────────────────────────
CREATE TABLE admins (
    id            UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    name          TEXT        NOT NULL,
    phone         TEXT        UNIQUE,
    email         TEXT        UNIQUE NOT NULL,
    password_hash TEXT        NOT NULL,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── members ──────────────────────────────────────────────────────────────────
CREATE TABLE members (
    id                   UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    name                 TEXT          NOT NULL,
    phone                TEXT          NOT NULL,
    password_hash        TEXT          NOT NULL,
    goal                 TEXT,
    join_date            DATE          NOT NULL DEFAULT CURRENT_DATE,
    current_weight       NUMERIC(5,2),
    status               TEXT          NOT NULL DEFAULT 'active',
    must_change_password BOOLEAN       NOT NULL DEFAULT TRUE,
    created_at           TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at           TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    CONSTRAINT members_status_check CHECK (status IN ('active', 'inactive'))
);

-- ── plan_templates ───────────────────────────────────────────────────────────
CREATE TABLE plan_templates (
    id            UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    name          TEXT          NOT NULL,
    duration_days INTEGER       NOT NULL,
    default_price NUMERIC(10,2) NOT NULL,
    created_at    TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

-- ── subscriptions ────────────────────────────────────────────────────────────
CREATE TABLE subscriptions (
    id               UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    member_id        UUID          NOT NULL REFERENCES members(id)       ON DELETE CASCADE,
    plan_template_id UUID          NOT NULL REFERENCES plan_templates(id),
    start_date       DATE          NOT NULL,
    end_date         DATE          NOT NULL,
    final_price      NUMERIC(10,2) NOT NULL,
    note             TEXT,
    status           TEXT          NOT NULL DEFAULT 'active',
    created_at       TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    CONSTRAINT subscriptions_status_check CHECK (status IN ('active', 'expired', 'replaced'))
);

-- ── payments ─────────────────────────────────────────────────────────────────
CREATE TABLE payments (
    id                   UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
    member_id            UUID          NOT NULL REFERENCES members(id)  ON DELETE CASCADE,
    subscription_id      UUID          NOT NULL REFERENCES subscriptions(id),
    amount               NUMERIC(10,2) NOT NULL,
    method               TEXT          NOT NULL,
    paid_at              TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    recorded_by_admin_id UUID          NOT NULL REFERENCES admins(id),
    created_at           TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    CONSTRAINT payments_method_check CHECK (method IN ('Cash', 'bKash', 'Nagad', 'Card'))
);

-- ── weight_logs ──────────────────────────────────────────────────────────────
CREATE TABLE weight_logs (
    id        UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    member_id UUID         NOT NULL REFERENCES members(id) ON DELETE CASCADE,
    weight_kg NUMERIC(5,2) NOT NULL,
    logged_at TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

-- ── workout_logs ─────────────────────────────────────────────────────────────
CREATE TABLE workout_logs (
    id        UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    member_id UUID        NOT NULL REFERENCES members(id) ON DELETE CASCADE,
    content   TEXT        NOT NULL,
    logged_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── diet_logs ────────────────────────────────────────────────────────────────
CREATE TABLE diet_logs (
    id        UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    member_id UUID        NOT NULL REFERENCES members(id) ON DELETE CASCADE,
    content   TEXT        NOT NULL,
    logged_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── messages ─────────────────────────────────────────────────────────────────
CREATE TABLE messages (
    id               UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    sender_id        UUID        NOT NULL,
    sender_role      TEXT        NOT NULL,
    receiver_id      UUID,
    is_broadcast     BOOLEAN     NOT NULL DEFAULT FALSE,
    broadcast_filter TEXT,
    content          TEXT        NOT NULL,
    sent_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    read_at          TIMESTAMPTZ,
    CONSTRAINT messages_sender_role_check CHECK (sender_role IN ('admin', 'member')),
    CONSTRAINT messages_broadcast_filter_check CHECK (
        broadcast_filter IS NULL OR
        broadcast_filter IN ('all', 'active', 'expired', 'expiring')
    )
);

-- ── notifications ────────────────────────────────────────────────────────────
CREATE TABLE notifications (
    id           UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    member_id    UUID        NOT NULL REFERENCES members(id) ON DELETE CASCADE,
    type         TEXT        NOT NULL,
    payload      JSONB       NOT NULL DEFAULT '{}',
    scheduled_at TIMESTAMPTZ NOT NULL,
    sent_at      TIMESTAMPTZ,
    status       TEXT        NOT NULL DEFAULT 'pending',
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT notifications_type_check   CHECK (type   IN ('renewal', 'weight_reminder', 'message')),
    CONSTRAINT notifications_status_check CHECK (status IN ('pending', 'sent', 'failed'))
);

-- ── fcm_tokens ───────────────────────────────────────────────────────────────
CREATE TABLE fcm_tokens (
    id             UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    member_id      UUID        NOT NULL REFERENCES members(id) ON DELETE CASCADE,
    token          TEXT        NOT NULL UNIQUE,
    device_info    TEXT,
    last_active_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── settings ─────────────────────────────────────────────────────────────────
CREATE TABLE settings (
    key        TEXT        PRIMARY KEY,
    value      JSONB       NOT NULL DEFAULT '{}',
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── system_logs ──────────────────────────────────────────────────────────────
-- PK is supplied by the application (uuid.New()) so no DEFAULT needed.
CREATE TABLE system_logs (
    id         UUID        PRIMARY KEY,
    level      TEXT        NOT NULL,
    message    TEXT        NOT NULL,
    request_id UUID,
    user_id    UUID,
    route      TEXT,
    metadata   JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ── Indexes ───────────────────────────────────────────────────────────────────
CREATE UNIQUE INDEX idx_members_phone                 ON members       (phone);
CREATE INDEX         idx_subscriptions_member_status  ON subscriptions (member_id, status);
CREATE INDEX         idx_subscriptions_end_date       ON subscriptions (end_date);
CREATE INDEX         idx_payments_member_paid_at      ON payments      (member_id, paid_at);
CREATE INDEX         idx_weight_logs_member_logged_at ON weight_logs   (member_id, logged_at);
CREATE INDEX         idx_notifications_sched_status   ON notifications (scheduled_at, status);
CREATE INDEX         idx_system_logs_created_at       ON system_logs   (created_at);

-- ── Seed default settings ────────────────────────────────────────────────────
INSERT INTO settings (key, value) VALUES
    ('quiet_window',         '{"start": "22:00", "end": "07:00"}'),
    ('nudge_days',           '7'),
    ('weight_reminder_days', '7');
