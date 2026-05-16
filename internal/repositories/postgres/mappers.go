// Package postgres contains pure database implementations of the repository
// interfaces. No cache logic lives here — use the cached/ decorators.
package postgres

import (
	"database/sql"

	sqlcdb "github.com/asadlive84/fitness-care-bagerhat/internal/database/sqlc"
	"github.com/asadlive84/fitness-care-bagerhat/internal/models"
)

func mapMember(row sqlcdb.Member) *models.Member {
	m := &models.Member{
		ID:                 row.ID,
		Name:               row.Name,
		Phone:              row.Phone,
		JoinDate:           row.JoinDate,
		Status:             row.Status,
		MustChangePassword: row.MustChangePassword,
		CreatedAt:          row.CreatedAt,
		UpdatedAt:          row.UpdatedAt,
	}
	if row.Goal.Valid {
		m.Goal = &row.Goal.String
	}
	if row.CurrentWeight.Valid {
		m.CurrentWeight = &row.CurrentWeight.Float64
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
	}
	if row.Phone.Valid {
		a.Phone = &row.Phone.String
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
	return &models.Setting{
		Key:       row.Key,
		Value:     row.Value,
		UpdatedAt: row.UpdatedAt,
	}
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
