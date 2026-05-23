CREATE TABLE profile_picture_updates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    member_id UUID NOT NULL REFERENCES members(id) ON DELETE CASCADE,
    updated_by_role TEXT NOT NULL CHECK (updated_by_role IN ('admin', 'member')),
    updated_by_id UUID NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_profile_picture_updates_member ON profile_picture_updates(member_id, updated_by_role);
