CREATE TABLE expenses (
    id            UUID           PRIMARY KEY DEFAULT gen_random_uuid(),
    amount        NUMERIC(10,2)  NOT NULL,
    description   TEXT           NOT NULL,
    category      TEXT           NOT NULL, -- 'Water', 'Bill', 'Salary', 'Rent', 'Maintenance', 'Others'
    spent_at      TIMESTAMPTZ    NOT NULL DEFAULT NOW(),
    recorded_by   UUID           NOT NULL REFERENCES admins(id) ON DELETE CASCADE,
    created_at    TIMESTAMPTZ    NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ    NOT NULL DEFAULT NOW()
);

-- Index spent_at and category for fast filtering and calendar aggregations
CREATE INDEX idx_expenses_spent_at ON expenses(spent_at);
CREATE INDEX idx_expenses_category ON expenses(category);
