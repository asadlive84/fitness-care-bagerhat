package models

import (
	"time"

	"github.com/google/uuid"
)

// Message is a single chat entry — direct or broadcast.
type Message struct {
	ID              uuid.UUID  `json:"id"`
	SenderID        uuid.UUID  `json:"sender_id"`
	SenderRole      string     `json:"sender_role"`      // admin | member
	ReceiverID      *uuid.UUID `json:"receiver_id,omitempty"`
	IsBroadcast     bool       `json:"is_broadcast"`
	BroadcastFilter *string    `json:"broadcast_filter,omitempty"` // all|active|expired|expiring
	Content         string     `json:"content"`
	SentAt          time.Time  `json:"sent_at"`
	ReadAt          *time.Time `json:"read_at,omitempty"`
}

// ConversationSummary is one entry in the admin conversation list.
type ConversationSummary struct {
	MemberID    uuid.UUID `json:"member_id"`
	LastMessage string    `json:"last_message"`
	LastSentAt  time.Time `json:"last_sent_at"`
	SenderRole  string    `json:"sender_role"` // who sent the last message
}
