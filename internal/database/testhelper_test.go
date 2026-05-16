package database_test

import (
	"database/sql"
	"os"
	"path/filepath"
	"runtime"
	"testing"

	"github.com/golang-migrate/migrate/v4"
	_ "github.com/golang-migrate/migrate/v4/database/postgres"
	_ "github.com/golang-migrate/migrate/v4/source/file"
	_ "github.com/lib/pq"
)

// testDSN returns the DSN to use in integration tests.
// Tests are skipped when DATABASE_TEST_DSN is unset.
func testDSN(t *testing.T) string {
	t.Helper()
	dsn := os.Getenv("DATABASE_TEST_DSN")
	if dsn == "" {
		t.Skip("DATABASE_TEST_DSN not set — skipping DB integration test")
	}
	return dsn
}

// openAndMigrate opens a DB, applies all migrations, and registers a cleanup
// that rolls them back. Returns a ready-to-use *sql.DB.
func openAndMigrate(t *testing.T, dsn string) *sql.DB {
	t.Helper()

	db, err := sql.Open("postgres", dsn)
	if err != nil {
		t.Fatalf("open db: %v", err)
	}

	migrationsPath := migrationsDir(t)
	m, err := migrate.New("file://"+migrationsPath, dsn)
	if err != nil {
		t.Fatalf("create migrator: %v", err)
	}

	if err := m.Up(); err != nil && err != migrate.ErrNoChange {
		t.Fatalf("migrate up: %v", err)
	}

	t.Cleanup(func() {
		if err := m.Down(); err != nil && err != migrate.ErrNoChange {
			t.Logf("migrate down (cleanup): %v", err)
		}
		m.Close()
		db.Close()
	})

	return db
}

// migrationsDir resolves the absolute path to the migrations folder
// regardless of where the test binary is invoked from.
func migrationsDir(t *testing.T) string {
	t.Helper()
	_, file, _, ok := runtime.Caller(0)
	if !ok {
		t.Fatal("runtime.Caller failed")
	}
	// file is …/internal/database/testhelper_test.go
	// migrations are at …/migrations/
	return filepath.Join(filepath.Dir(file), "..", "..", "migrations")
}
