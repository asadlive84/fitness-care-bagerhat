package services

import (
	"context"
	"crypto/rand"
	"errors"
	"fmt"
	"math/big"
	"time"

	"github.com/asadlive84/fitness-care-bagerhat/internal/models"
	"github.com/asadlive84/fitness-care-bagerhat/internal/repositories"
	"github.com/google/uuid"
	"golang.org/x/crypto/bcrypt"
)

// CreateMemberRequest carries validated input for member creation.
type CreateMemberRequest struct {
	Name             string
	Phone            string
	Gender           string
	Goal             *string
	JoinDate         time.Time
	CurrentWeight    *float64
	HeightCm         *float64
	DateOfBirth      *time.Time
	Religion         *string
	BloodGroup       *string
	Hobbies          []string
	PresentAddress   *string
	PermanentAddress *string
	Occupation       *string
	NID              *string
	EmergencyPhone   *string
	CreatedByAdminID *uuid.UUID
	IsAIAllowed        bool
	IsAIFoodLogAllowed bool
}

// CreateMemberResult bundles the new member with its one-time temp password.
// The plaintext password is only returned here — admin must record it before
// sharing with the member.
type CreateMemberResult struct {
	Member       *models.Member `json:"member"`
	TempPassword string         `json:"temp_password"`
}

// UpdateMemberRequest carries validated profile fields for member update.
type UpdateMemberRequest struct {
	Name             string
	Phone            string
	Gender           string
	Goal             *string
	CurrentWeight    *float64
	HeightCm         *float64
	DateOfBirth      *time.Time
	Religion         *string
	BloodGroup       *string
	Hobbies          []string
	PresentAddress   *string
	PermanentAddress *string
	Occupation       *string
	NID              *string
	EmergencyPhone   *string
}

// MemberService handles member CRUD business logic.
type MemberService struct {
	members repositories.MemberRepository
	weights repositories.WeightLogRepository
}

// NewMemberService constructs a MemberService.
func NewMemberService(members repositories.MemberRepository, weights repositories.WeightLogRepository) *MemberService {
	return &MemberService{members: members, weights: weights}
}

// CreateMember creates a new member with a cryptographically random temp password.
func (s *MemberService) CreateMember(ctx context.Context, req CreateMemberRequest) (*CreateMemberResult, error) {
	tempPass, err := generateTempPassword()
	if err != nil {
		return nil, fmt.Errorf("generate temp password: %w", err)
	}

	hash, err := bcrypt.GenerateFromPassword([]byte(tempPass), 12)
	if err != nil {
		return nil, fmt.Errorf("hash temp password: %w", err)
	}

	joinDate := req.JoinDate
	if joinDate.IsZero() {
		joinDate = time.Now()
	}

	member := &models.Member{
		ID:                 uuid.New(),
		Name:               req.Name,
		Phone:              req.Phone,
		Gender:             req.Gender,
		Goal:               req.Goal,
		JoinDate:           joinDate,
		CurrentWeight:      req.CurrentWeight,
		HeightCm:           req.HeightCm,
		DateOfBirth:        req.DateOfBirth,
		Religion:           req.Religion,
		BloodGroup:         req.BloodGroup,
		Hobbies:            req.Hobbies,
		PresentAddress:     req.PresentAddress,
		PermanentAddress:   req.PermanentAddress,
		Occupation:         req.Occupation,
		NID:                req.NID,
		EmergencyPhone:     req.EmergencyPhone,
		Status:             "active",
		MustChangePassword: true,
		CreatedAt:          time.Now(),
		UpdatedAt:          time.Now(),
		CreatedByAdminID:   req.CreatedByAdminID,
		IsAIAllowed:        req.IsAIAllowed,
		IsAIFoodLogAllowed: req.IsAIFoodLogAllowed,
	}

	if err := s.members.Create(ctx, member, string(hash)); err != nil {
		if isConflict(err) {
			return nil, fmt.Errorf("%w: phone number already registered", ErrConflict)
		}
		return nil, fmt.Errorf("create member: %w", err)
	}

	if req.CurrentWeight != nil {
		if err := s.weights.Create(ctx, member.ID, *req.CurrentWeight, joinDate); err != nil {
			// Best effort: don't fail member creation if logging weight fails
		}
	}

	return &CreateMemberResult{Member: member, TempPassword: tempPass}, nil
}

// GetMember returns a single member by ID.
func (s *MemberService) GetMember(ctx context.Context, id uuid.UUID) (*models.Member, error) {
	m, err := s.members.GetByID(ctx, id)
	if err != nil {
		if isNotFound(err) {
			return nil, ErrNotFound
		}
		return nil, fmt.Errorf("get member: %w", err)
	}
	return m, nil
}

// ListMembers returns a paginated, filtered member list and the total count.
func (s *MemberService) ListMembers(ctx context.Context, f models.MemberFilter) ([]*models.Member, int64, error) {
	members, total, err := s.members.List(ctx, f)
	if err != nil {
		return nil, 0, fmt.Errorf("list members: %w", err)
	}
	return members, total, nil
}

// ListExpiringSoon returns active members whose subscription ends within
// nudgeDays days. The nudgeDays value will come from settings in Step 10;
// for now it defaults to 7.
func (s *MemberService) ListExpiringSoon(ctx context.Context) ([]*models.Member, error) {
	const nudgeDays = 7
	members, err := s.members.ListExpiringSoon(ctx, nudgeDays)
	if err != nil {
		return nil, fmt.Errorf("list expiring soon: %w", err)
	}
	return members, nil
}

// UpdateMember saves profile changes and returns the updated member.
func (s *MemberService) UpdateMember(ctx context.Context, id uuid.UUID, req UpdateMemberRequest) (*models.Member, error) {
	existing, err := s.members.GetByID(ctx, id)
	if err != nil {
		if isNotFound(err) {
			return nil, ErrNotFound
		}
		return nil, fmt.Errorf("fetch member for update: %w", err)
	}

	weightChanged := false
	if req.CurrentWeight != nil {
		if existing.CurrentWeight == nil || *existing.CurrentWeight != *req.CurrentWeight {
			weightChanged = true
		}
	}

	existing.Name             = req.Name
	existing.Phone            = req.Phone
	existing.Gender           = req.Gender
	existing.Goal              = req.Goal
	existing.CurrentWeight    = req.CurrentWeight
	existing.HeightCm         = req.HeightCm
	existing.DateOfBirth      = req.DateOfBirth
	existing.Religion         = req.Religion
	existing.BloodGroup       = req.BloodGroup
	existing.Hobbies          = req.Hobbies
	existing.PresentAddress   = req.PresentAddress
	existing.PermanentAddress = req.PermanentAddress
	existing.Occupation       = req.Occupation
	existing.NID              = req.NID
	existing.EmergencyPhone   = req.EmergencyPhone

	if err := s.members.Update(ctx, existing); err != nil {
		if isConflict(err) {
			return nil, fmt.Errorf("%w: phone number already registered", ErrConflict)
		}
		return nil, fmt.Errorf("update member: %w", err)
	}

	if weightChanged && req.CurrentWeight != nil {
		_ = s.weights.Create(ctx, existing.ID, *req.CurrentWeight, time.Now())
	}

	return existing, nil
}

// UpdateMemberStatus sets a member's active/inactive status.
func (s *MemberService) UpdateMemberStatus(ctx context.Context, id uuid.UUID, status string) error {
	if err := s.members.UpdateStatus(ctx, id, status); err != nil {
		if isNotFound(err) {
			return ErrNotFound
		}
		return fmt.Errorf("update member status: %w", err)
	}
	return nil
}

// ResetPasswordResult bundles the new temp password returned to the admin.
type ResetPasswordResult struct {
	TempPassword string `json:"temp_password"`
}

// RegisterMemberRequest carries self-registration input from a prospective member.
type RegisterMemberRequest struct {
	Name           string
	Phone          string
	Email          *string
	Gender         string
	Religion       *string
	DateOfBirth    *time.Time
	NID            *string
	PresentAddress *string
	HeightCm       *float64
	CurrentWeight  *float64
}

// ApproveMemberResult bundles the approved member with its one-time temp password.
type ApproveMemberResult struct {
	Member       *models.Member `json:"member"`
	TempPassword string         `json:"temp_password"`
}

// ResetMemberPassword generates a new cryptographically random temp password,
// hashes it, stores it, and returns the plaintext so the admin can hand it to
// the member. The member will be required to change it on next login.
func (s *MemberService) ResetMemberPassword(ctx context.Context, id uuid.UUID) (*ResetPasswordResult, error) {
	if _, err := s.members.GetByID(ctx, id); err != nil {
		if isNotFound(err) {
			return nil, ErrNotFound
		}
		return nil, fmt.Errorf("fetch member for password reset: %w", err)
	}

	tempPass, err := generateTempPassword()
	if err != nil {
		return nil, fmt.Errorf("generate temp password: %w", err)
	}

	hash, err := bcrypt.GenerateFromPassword([]byte(tempPass), 12)
	if err != nil {
		return nil, fmt.Errorf("hash password: %w", err)
	}

	if err := s.members.ResetPasswordByAdmin(ctx, id, string(hash)); err != nil {
		return nil, fmt.Errorf("store reset password: %w", err)
	}

	return &ResetPasswordResult{TempPassword: tempPass}, nil
}

// InvalidateCache clears the cached member profile.
func (s *MemberService) InvalidateCache(ctx context.Context, id uuid.UUID, phone string) error {
	return s.members.InvalidateCache(ctx, id, phone)
}

// DeleteMember permanently removes a member and all their associated data.
func (s *MemberService) DeleteMember(ctx context.Context, id uuid.UUID) error {
	if err := s.members.Delete(ctx, id); err != nil {
		if isNotFound(err) {
			return ErrNotFound
		}
		return fmt.Errorf("delete member: %w", err)
	}
	return nil
}

// RegisterMember creates a pending member from a self-registration request.
// No password is set; the member cannot log in until approved.
func (s *MemberService) RegisterMember(ctx context.Context, req RegisterMemberRequest) (*models.Member, error) {
	member := &models.Member{
		ID:             uuid.New(),
		Name:           req.Name,
		Phone:          req.Phone,
		Email:          req.Email,
		Gender:         req.Gender,
		Religion:       req.Religion,
		DateOfBirth:    req.DateOfBirth,
		NID:            req.NID,
		PresentAddress: req.PresentAddress,
		HeightCm:       req.HeightCm,
		CurrentWeight:  req.CurrentWeight,
		JoinDate:       time.Now(),
		Status:         "pending",
		CreatedAt:      time.Now(),
		UpdatedAt:      time.Now(),
	}

	if err := s.members.Create(ctx, member, ""); err != nil {
		if isConflict(err) {
			return nil, fmt.Errorf("%w: phone number already registered", ErrConflict)
		}
		return nil, fmt.Errorf("register member: %w", err)
	}
	return member, nil
}

// ApproveMember activates a pending member and assigns a temporary password.
func (s *MemberService) ApproveMember(ctx context.Context, id uuid.UUID) (*ApproveMemberResult, error) {
	member, err := s.members.GetByID(ctx, id)
	if err != nil {
		if isNotFound(err) {
			return nil, ErrNotFound
		}
		return nil, fmt.Errorf("get member: %w", err)
	}
	if member.Status != "pending" {
		return nil, fmt.Errorf("%w: member is not pending", ErrConflict)
	}

	tempPass, err := generateTempPassword()
	if err != nil {
		return nil, fmt.Errorf("generate temp password: %w", err)
	}
	hash, err := bcrypt.GenerateFromPassword([]byte(tempPass), 12)
	if err != nil {
		return nil, fmt.Errorf("hash temp password: %w", err)
	}

	if err := s.members.ResetPasswordByAdmin(ctx, id, string(hash)); err != nil {
		return nil, fmt.Errorf("set password: %w", err)
	}
	if err := s.members.UpdateStatus(ctx, id, "active"); err != nil {
		return nil, fmt.Errorf("activate member: %w", err)
	}

	member.Status = "active"
	member.MustChangePassword = true
	return &ApproveMemberResult{Member: member, TempPassword: tempPass}, nil
}

// RejectMember marks a pending member as rejected.
func (s *MemberService) RejectMember(ctx context.Context, id uuid.UUID) error {
	member, err := s.members.GetByID(ctx, id)
	if err != nil {
		if isNotFound(err) {
			return ErrNotFound
		}
		return fmt.Errorf("get member: %w", err)
	}
	if member.Status != "pending" {
		return fmt.Errorf("%w: member is not pending", ErrConflict)
	}
	return s.members.UpdateStatus(ctx, id, "rejected")
}

// ── helpers ───────────────────────────────────────────────────────────────────

// generateTempPassword returns an 8-character cryptographically random string.
// Characters are chosen from an unambiguous alphabet (no 0/O, 1/I/l).
func generateTempPassword() (string, error) {
	const alphabet = "abcdefghjkmnpqrstuvwxyzABCDEFGHJKMNPQRSTUVWXYZ23456789"
	b := make([]byte, 8)
	for i := range b {
		n, err := rand.Int(rand.Reader, big.NewInt(int64(len(alphabet))))
		if err != nil {
			return "", err
		}
		b[i] = alphabet[n.Int64()]
	}
	return string(b), nil
}

func isNotFound(err error) bool { return errors.Is(err, repositories.ErrNotFound) }
func isConflict(err error) bool  { return errors.Is(err, repositories.ErrConflict) }
