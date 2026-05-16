package database

import (
	"context"
	"database/sql"
	"fmt"
	"time"

	"github.com/asadlive84/fitness-care-bagerhat/internal/config"
	_ "github.com/lib/pq"
)

// Open opens a Postgres connection pool and verifies connectivity.
func Open(cfg config.DatabaseConfig) (*sql.DB, error) {
	db, err := sql.Open("postgres", cfg.DSN)
	if err != nil {
		return nil, fmt.Errorf("open db: %w", err)
	}

	db.SetMaxOpenConns(cfg.MaxOpenConns)
	db.SetMaxIdleConns(cfg.MaxIdleConns)
	db.SetConnMaxLifetime(cfg.ConnMaxLifetime)

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := db.PingContext(ctx); err != nil {
		return nil, fmt.Errorf("ping db: %w", err)
	}

	return db, nil
}

// Ping checks the database connectivity with a short timeout.
func Ping(ctx context.Context, db *sql.DB) error {
	pingCtx, cancel := context.WithTimeout(ctx, 2*time.Second)
	defer cancel()
	return db.PingContext(pingCtx)
}
