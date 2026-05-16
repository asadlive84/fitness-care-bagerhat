package services

import (
	"context"
	"fmt"
	"sort"
	"time"

	"github.com/asadlive84/fitness-care-bagerhat/internal/models"
	"github.com/asadlive84/fitness-care-bagerhat/internal/repositories"
	"github.com/google/uuid"
)

// ValidBroadcastFilters is the accepted set of broadcast audience filters.
var ValidBroadcastFilters = map[string]bool{
	"all":      true,
	"active":   true,
	"expired":  true,
	"expiring": true,
}

// MessageService handles all messaging logic — admin and member directions.
type MessageService struct {
	msgs repositories.MessageRepository
}

// NewMessageService constructs a MessageService.
func NewMessageService(msgs repositories.MessageRepository) *MessageService {
	return &MessageService{msgs: msgs}
}

// SendBroadcast creates a broadcast message from admin to a filtered audience.
// Actual FCM delivery is handled by the scheduler in Step 10.
func (s *MessageService) SendBroadcast(ctx context.Context, adminID uuid.UUID, content, broadcastFilter string) (*models.Message, error) {
	msg := &models.Message{
		ID:              uuid.New(),
		SenderID:        adminID,
		SenderRole:      "admin",
		IsBroadcast:     true,
		BroadcastFilter: &broadcastFilter,
		Content:         content,
		SentAt:          time.Now(),
	}
	if err := s.msgs.Create(ctx, msg); err != nil {
		return nil, fmt.Errorf("send broadcast: %w", err)
	}
	return msg, nil
}

// SendDirect sends a 1-on-1 message from admin to a member.
func (s *MessageService) SendDirect(ctx context.Context, adminID, memberID uuid.UUID, content string) (*models.Message, error) {
	msg := &models.Message{
		ID:          uuid.New(),
		SenderID:    adminID,
		SenderRole:  "admin",
		ReceiverID:  &memberID,
		IsBroadcast: false,
		Content:     content,
		SentAt:      time.Now(),
	}
	if err := s.msgs.Create(ctx, msg); err != nil {
		return nil, fmt.Errorf("send direct message: %w", err)
	}
	return msg, nil
}

// GetConversations returns a summary of each member conversation, sorted by
// most recent activity. Uses N+1 queries — acceptable for a single gym.
func (s *MessageService) GetConversations(ctx context.Context) ([]*models.ConversationSummary, error) {
	memberIDs, err := s.msgs.ListConversationMemberIDs(ctx)
	if err != nil {
		return nil, fmt.Errorf("get conversation member ids: %w", err)
	}

	summaries := make([]*models.ConversationSummary, 0, len(memberIDs))
	for _, memberID := range memberIDs {
		latest, err := s.msgs.GetLatestDirectByMember(ctx, memberID)
		if err != nil {
			continue // skip members where we can't get the latest message
		}
		summaries = append(summaries, &models.ConversationSummary{
			MemberID:    memberID,
			LastMessage: latest.Content,
			LastSentAt:  latest.SentAt,
			SenderRole:  latest.SenderRole,
		})
	}

	// Sort newest-first.
	sort.Slice(summaries, func(i, j int) bool {
		return summaries[i].LastSentAt.After(summaries[j].LastSentAt)
	})
	return summaries, nil
}

// GetConversation returns all messages between admin and a member.
// Marks the member's unread messages as read (admin is viewing).
func (s *MessageService) GetConversation(ctx context.Context, memberID uuid.UUID) ([]*models.Message, error) {
	msgs, err := s.msgs.ListDirectByMember(ctx, memberID)
	if err != nil {
		return nil, fmt.Errorf("get conversation: %w", err)
	}

	// Mark member→admin messages as read (best-effort).
	_ = s.msgs.MarkMemberMessagesRead(ctx, memberID)

	return msgs, nil
}

// GetMemberMessages returns all messages visible to a member (direct + broadcasts).
// Marks unread admin→member messages as read.
func (s *MessageService) GetMemberMessages(ctx context.Context, memberID uuid.UUID, page, limit int) ([]*models.Message, error) {
	msgs, err := s.msgs.ListMemberMessages(ctx, memberID, page, limit)
	if err != nil {
		return nil, fmt.Errorf("get member messages: %w", err)
	}

	// Mark admin→member messages as read (best-effort).
	_ = s.msgs.MarkAdminMessagesRead(ctx, memberID)

	return msgs, nil
}

// MemberSendMessage creates a direct message from a member to admin.
// receiver_id is nil because there is only one admin.
func (s *MessageService) MemberSendMessage(ctx context.Context, memberID uuid.UUID, content string) (*models.Message, error) {
	msg := &models.Message{
		ID:          uuid.New(),
		SenderID:    memberID,
		SenderRole:  "member",
		IsBroadcast: false,
		Content:     content,
		SentAt:      time.Now(),
	}
	if err := s.msgs.Create(ctx, msg); err != nil {
		return nil, fmt.Errorf("send member message: %w", err)
	}
	return msg, nil
}
