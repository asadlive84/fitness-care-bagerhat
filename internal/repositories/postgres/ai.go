package postgres

import (
	"context"
	"database/sql"

	"github.com/asadlive84/fitness-care-bagerhat/internal/database/sqlc"
	"github.com/google/uuid"
)

type AIRepo struct {
	db *sqlcdb.Queries
}

func NewAIRepo(db *sql.DB) *AIRepo {
	return &AIRepo{
		db: sqlcdb.New(db),
	}
}

func (r *AIRepo) GetSystemSetting(ctx context.Context, key string, adminID *uuid.UUID) (sqlcdb.SystemSetting, error) {
	return r.db.GetSystemSetting(ctx, sqlcdb.GetSystemSettingParams{
		SettingKey: key,
		AdminID:    nullUUID(adminID),
	})
}

func (r *AIRepo) UpdateSystemSetting(ctx context.Context, key, value string, adminID *uuid.UUID) error {
	return r.db.UpdateSystemSetting(ctx, sqlcdb.UpdateSystemSettingParams{
		SettingKey:   key,
		SettingValue: value,
		AdminID:      nullUUID(adminID),
	})
}

func (r *AIRepo) GetAIPrompt(ctx context.Context, promptType string, adminID *uuid.UUID) (sqlcdb.AiPrompt, error) {
	return r.db.GetAIPrompt(ctx, sqlcdb.GetAIPromptParams{
		PromptType: promptType,
		AdminID:    nullUUID(adminID),
	})
}

func (r *AIRepo) CountDailyFoodUploads(ctx context.Context, arg sqlcdb.CountDailyFoodUploadsParams) (int64, error) {
	return r.db.CountDailyFoodUploads(ctx, arg)
}

func (r *AIRepo) CreateMemberFoodLog(ctx context.Context, arg sqlcdb.CreateMemberFoodLogParams) (sqlcdb.MemberFoodLog, error) {
	return r.db.CreateMemberFoodLog(ctx, arg)
}

func (r *AIRepo) LogAITokenUsage(ctx context.Context, arg sqlcdb.LogAITokenUsageParams) (sqlcdb.AiTokenLog, error) {
	return r.db.LogAITokenUsage(ctx, arg)
}

func (r *AIRepo) UpdateMemberAIProfile(ctx context.Context, arg sqlcdb.UpdateMemberAIProfileParams) (sqlcdb.Member, error) {
	return r.db.UpdateMemberAIProfile(ctx, arg)
}

func (r *AIRepo) CountProfilePictureUpdates(ctx context.Context, arg sqlcdb.CountProfilePictureUpdatesParams) (int64, error) {
	return r.db.CountProfilePictureUpdates(ctx, arg)
}

func (r *AIRepo) RecordProfilePictureUpdate(ctx context.Context, arg sqlcdb.RecordProfilePictureUpdateParams) (sqlcdb.ProfilePictureUpdate, error) {
	return r.db.RecordProfilePictureUpdate(ctx, arg)
}

func (r *AIRepo) ListMemberFoodLogs(ctx context.Context, arg sqlcdb.ListMemberFoodLogsParams) ([]sqlcdb.MemberFoodLog, error) {
	return r.db.ListMemberFoodLogs(ctx, arg)
}

func (r *AIRepo) UpdateMemberDietChart(ctx context.Context, arg sqlcdb.UpdateMemberDietChartParams) (sqlcdb.Member, error) {
	return r.db.UpdateMemberDietChart(ctx, arg)
}

func (r *AIRepo) UpdateMemberPendingDietChart(ctx context.Context, arg sqlcdb.UpdateMemberPendingDietChartParams) (sqlcdb.Member, error) {
	return r.db.UpdateMemberPendingDietChart(ctx, arg)
}

func (r *AIRepo) ApprovePendingDietChart(ctx context.Context, id uuid.UUID) (sqlcdb.Member, error) {
	return r.db.ApprovePendingDietChart(ctx, id)
}

func (r *AIRepo) DeclinePendingDietChart(ctx context.Context, id uuid.UUID) (sqlcdb.Member, error) {
	return r.db.DeclinePendingDietChart(ctx, id)
}

func (r *AIRepo) LogAIAuditUsage(ctx context.Context, arg sqlcdb.LogAIAuditUsageParams) (sqlcdb.SuperadminAiAuditLog, error) {
	return r.db.LogAIAuditUsage(ctx, arg)
}

// ── SuperAdmin audit listings ───────────────────────────────────────────────

func (r *AIRepo) ListAIAuditLogs(ctx context.Context, arg sqlcdb.ListAIAuditLogsParams) ([]sqlcdb.SuperadminAiAuditLog, error) {
	return r.db.ListAIAuditLogs(ctx, arg)
}

func (r *AIRepo) CountAIAuditLogs(ctx context.Context, arg sqlcdb.CountAIAuditLogsParams) (int64, error) {
	return r.db.CountAIAuditLogs(ctx, arg)
}

func (r *AIRepo) AICostByGym(ctx context.Context, arg sqlcdb.AICostByGymParams) ([]sqlcdb.AICostByGymRow, error) {
	return r.db.AICostByGym(ctx, arg)
}

func (r *AIRepo) AIHeavyUsers(ctx context.Context, arg sqlcdb.AIHeavyUsersParams) ([]sqlcdb.AIHeavyUsersRow, error) {
	return r.db.AIHeavyUsers(ctx, arg)
}

func (r *AIRepo) UpdateAIPromptGlobal(ctx context.Context, promptType string, promptText string, isActive bool) error {
	return r.db.UpdateAIPromptGlobal(ctx, sqlcdb.UpdateAIPromptGlobalParams{
		PromptType: promptType,
		PromptText: promptText,
		IsActive:   isActive,
	})
}

func (r *AIRepo) UpdateAIPromptTenant(ctx context.Context, promptType string, promptText string, isActive bool, adminID uuid.UUID) error {
	return r.db.UpdateAIPromptTenant(ctx, sqlcdb.UpdateAIPromptTenantParams{
		PromptType: promptType,
		PromptText: promptText,
		IsActive:   isActive,
		AdminID:    uuid.NullUUID{UUID: adminID, Valid: true},
	})
}

func (r *AIRepo) GetAITokenUsagePerUser(ctx context.Context) ([]sqlcdb.GetAITokenUsagePerUserRow, error) {
	return r.db.GetAITokenUsagePerUser(ctx)
}

func (r *AIRepo) GetAITokenUsageForUser(ctx context.Context, memberID uuid.UUID) (sqlcdb.GetAITokenUsageForUserRow, error) {
	return r.db.GetAITokenUsageForUser(ctx, memberID)
}

func (r *AIRepo) GetAITokenUsagePerAdmin(ctx context.Context) ([]sqlcdb.GetAITokenUsagePerAdminRow, error) {
	return r.db.GetAITokenUsagePerAdmin(ctx)
}

func (r *AIRepo) CountDietChartsGenerated(ctx context.Context, memberID uuid.UUID) (int64, error) {
	return r.db.CountDietChartsGenerated(ctx, memberID)
}



