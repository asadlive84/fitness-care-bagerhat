package logger

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"log/slog"
	"sync"
	"time"

	"github.com/google/uuid"
)

const (
	bufferSize    = 512          // max queued log entries
	flushInterval = 2 * time.Second
	flushBatch    = 100
)

// LogEntry mirrors the system_logs table row.
type LogEntry struct {
	ID        uuid.UUID       `json:"id"`
	Level     string          `json:"level"`
	Message   string          `json:"message"`
	RequestID *string         `json:"request_id,omitempty"`
	UserID    *string         `json:"user_id,omitempty"`
	Route     *string         `json:"route,omitempty"`
	Metadata  json.RawMessage `json:"metadata,omitempty"`
	CreatedAt time.Time       `json:"created_at"`
}

// DBSink is an io.Writer that parses JSON log lines and asynchronously
// batch-inserts them into the system_logs Postgres table.
type DBSink struct {
	ch     chan LogEntry
	db     *sql.DB
	stdout *slog.Logger // fallback — only used inside DBSink itself
	once   sync.Once
	done   chan struct{}
}

// NewDBSink creates a DBSink and starts the background drain goroutine.
// Call Close() on shutdown to flush remaining entries.
func NewDBSink(db *sql.DB) *DBSink {
	s := &DBSink{
		ch:   make(chan LogEntry, bufferSize),
		db:   db,
		done: make(chan struct{}),
	}
	go s.drain()
	return s
}

// Write implements io.Writer. It parses the JSON log line emitted by slog
// and enqueues a LogEntry. If the buffer is full, the oldest entry is dropped.
func (s *DBSink) Write(p []byte) (int, error) {
	var raw map[string]any
	if err := json.Unmarshal(p, &raw); err != nil {
		// Non-JSON line (e.g., text handler in dev) — skip DB insertion.
		return len(p), nil
	}

	entry := LogEntry{
		ID:        uuid.New(),
		Level:     stringVal(raw, "level"),
		Message:   stringVal(raw, "msg"),
		CreatedAt: time.Now().UTC(),
	}

	if rid := stringVal(raw, "request_id"); rid != "" {
		entry.RequestID = &rid
	}
	if uid := stringVal(raw, "user_id"); uid != "" {
		entry.UserID = &uid
	}
	if route := stringVal(raw, "path"); route != "" {
		entry.Route = &route
	}

	// Store full payload as metadata JSONB.
	if meta, err := json.Marshal(raw); err == nil {
		entry.Metadata = meta
	}

	select {
	case s.ch <- entry:
	default:
		// Buffer full: drop oldest to make room, then enqueue new.
		select {
		case <-s.ch:
		default:
		}
		select {
		case s.ch <- entry:
		default:
		}
		fmt.Println(`{"level":"WARN","msg":"db log buffer full, entry dropped"}`)
	}

	return len(p), nil
}

// Close signals the drain goroutine to flush and stop.
func (s *DBSink) Close() {
	s.once.Do(func() { close(s.done) })
}

// drain runs in the background, flushing entries every flushInterval or flushBatch.
func (s *DBSink) drain() {
	ticker := time.NewTicker(flushInterval)
	defer ticker.Stop()

	batch := make([]LogEntry, 0, flushBatch)

	flush := func() {
		if len(batch) == 0 {
			return
		}
		if err := s.insertBatch(batch); err != nil {
			fmt.Printf(`{"level":"WARN","msg":"db log flush failed","error":%q}`+"\n", err.Error())
		}
		batch = batch[:0]
	}

	for {
		select {
		case entry := <-s.ch:
			batch = append(batch, entry)
			if len(batch) >= flushBatch {
				flush()
			}
		case <-ticker.C:
			flush()
		case <-s.done:
			// Drain remaining entries.
			for len(s.ch) > 0 {
				batch = append(batch, <-s.ch)
				if len(batch) >= flushBatch {
					flush()
				}
			}
			flush()
			return
		}
	}
}

func (s *DBSink) insertBatch(entries []LogEntry) error {
	if len(entries) == 0 {
		return nil
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	tx, err := s.db.BeginTx(ctx, nil)
	if err != nil {
		return fmt.Errorf("begin tx: %w", err)
	}
	defer tx.Rollback() //nolint:errcheck

	stmt, err := tx.PrepareContext(ctx, `
		INSERT INTO system_logs (id, level, message, request_id, user_id, route, metadata, created_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
	`)
	if err != nil {
		return fmt.Errorf("prepare stmt: %w", err)
	}
	defer stmt.Close()

	for _, e := range entries {
		_, err := stmt.ExecContext(ctx,
			e.ID, e.Level, e.Message,
			e.RequestID, e.UserID, e.Route,
			e.Metadata, e.CreatedAt,
		)
		if err != nil {
			return fmt.Errorf("exec insert: %w", err)
		}
	}

	return tx.Commit()
}

func stringVal(m map[string]any, key string) string {
	if v, ok := m[key]; ok {
		if s, ok := v.(string); ok {
			return s
		}
	}
	return ""
}
