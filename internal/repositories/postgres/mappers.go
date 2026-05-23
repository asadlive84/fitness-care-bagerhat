// Package postgres contains pure database implementations of the repository
// interfaces. No cache logic lives here — use the cached/ decorators.
package postgres

import (
	"database/sql"
	"encoding/json"

	sqlcdb "github.com/asadlive84/fitness-care-bagerhat/internal/database/sqlc"
	"github.com/asadlive84/fitness-care-bagerhat/internal/models"
)

func mapMember(row sqlcdb.Member) *models.Member {
	m := &models.Member{
		ID:                 row.ID,
		Name:               row.Name,
		Phone:              row.Phone,
		JoinDate:           row.JoinDate,
		Gender:             row.Gender,
		Status:             row.Status,
		MustChangePassword: row.MustChangePassword,
		CreatedAt:          row.CreatedAt,
		UpdatedAt:          row.UpdatedAt,
		IsAIAllowed:        row.IsAiAllowed,
		IsAIFoodLogAllowed: row.IsAiFoodLogAllowed,
	}
	if row.Goal.Valid {
		m.Goal = &row.Goal.String
	}
	if row.CurrentWeight.Valid {
		m.CurrentWeight = &row.CurrentWeight.Float64
	}
	if row.HeightCm.Valid {
		m.HeightCm = &row.HeightCm.Float64
	}
	if row.DateOfBirth.Valid {
		m.DateOfBirth = &row.DateOfBirth.Time
	}
	if row.Religion.Valid {
		m.Religion = &row.Religion.String
	}
	if row.BloodGroup.Valid {
		m.BloodGroup = &row.BloodGroup.String
	}
	if len(row.Hobbies) > 0 {
		m.Hobbies = row.Hobbies
	}
	if row.PresentAddress.Valid {
		m.PresentAddress = &row.PresentAddress.String
	}
	if row.PermanentAddress.Valid {
		m.PermanentAddress = &row.PermanentAddress.String
	}
	if row.Occupation.Valid {
		m.Occupation = &row.Occupation.String
	}
	if row.Nid.Valid {
		m.NID = &row.Nid.String
	}
	if row.EmergencyPhone.Valid {
		m.EmergencyPhone = &row.EmergencyPhone.String
	}
	if row.BudgetLevel.Valid {
		m.BudgetLevel = &row.BudgetLevel.String
	}
	if row.ProfilePictureUrl.Valid {
		m.ProfilePictureURL = &row.ProfilePictureUrl.String
	}
	if row.DietChartJson.Valid {
		raw := json.RawMessage(row.DietChartJson.RawMessage)
		m.DietChartJSON = &raw
	}
	if row.PendingDietChartJson.Valid {
		raw := json.RawMessage(row.PendingDietChartJson.RawMessage)
		m.PendingDietChartJSON = &raw
	}
	if row.CreatedByAdminID.Valid {
		m.CreatedByAdminID = &row.CreatedByAdminID.UUID
	}
	return m
}

func mapAdmin(row sqlcdb.Admin) *models.Admin {
	a := &models.Admin{
		ID:        row.ID,
		Name:      row.Name,
		Email:     row.Email,
		CreatedAt: row.CreatedAt,
		UpdatedAt: row.UpdatedAt,
		Role:      row.Role,
	}
	if row.Phone.Valid {
		a.Phone = &row.Phone.String
	}
	if row.ParentAdminID.Valid {
		a.ParentAdminID = &row.ParentAdminID.UUID
	}
	if row.CreatedBySuperadminID.Valid {
		a.CreatedBySuperadminID = &row.CreatedBySuperadminID.UUID
	}
	return a
}

func mapPlan(row sqlcdb.PlanTemplate) *models.PlanTemplate {
	return &models.PlanTemplate{
		ID:           row.ID,
		Name:         row.Name,
		DurationDays: row.DurationDays,
		DefaultPrice: row.DefaultPrice,
		CreatedAt:    row.CreatedAt,
		UpdatedAt:    row.UpdatedAt,
	}
}

func mapSubscription(row sqlcdb.Subscription) *models.Subscription {
	s := &models.Subscription{
		ID:             row.ID,
		MemberID:       row.MemberID,
		PlanTemplateID: row.PlanTemplateID,
		StartDate:      row.StartDate,
		EndDate:        row.EndDate,
		FinalPrice:     row.FinalPrice,
		Status:         row.Status,
		CreatedAt:      row.CreatedAt,
	}
	if row.Note.Valid {
		s.Note = &row.Note.String
	}
	return s
}

func mapSetting(row sqlcdb.Setting) *models.Setting {
	s := &models.Setting{
		Key:       row.Key,
		Value:     row.Value,
		UpdatedAt: row.UpdatedAt,
	}
	if row.AdminID.Valid {
		s.AdminID = &row.AdminID.UUID
	}
	return s
}

func mapGetAllSettingsRow(row sqlcdb.GetAllSettingsRow) *models.Setting {
	s := &models.Setting{
		Key:       row.Key,
		Value:     row.Value,
		UpdatedAt: row.UpdatedAt,
	}
	if row.AdminID.Valid {
		s.AdminID = &row.AdminID.UUID
	}
	return s
}

func nullString(s *string) sql.NullString {
	if s == nil {
		return sql.NullString{}
	}
	return sql.NullString{String: *s, Valid: true}
}

func nullFloat64(f *float64) sql.NullFloat64 {
	if f == nil {
		return sql.NullFloat64{}
	}
	return sql.NullFloat64{Float64: *f, Valid: true}
}
