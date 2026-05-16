// cmd/seed/main.go — one-time admin account setup tool.
//
// Usage:
//
//	go run ./cmd/seed -name="Gym Owner" -email="owner@gym.bd" -phone="01711000000" -password="Admin@1234"
//	make seed/admin name="Gym Owner" email="owner@gym.bd" phone="01711000000" password="Admin@1234"
package main

import (
	"context"
	"database/sql"
	"flag"
	"fmt"
	"log"
	"os"
	"time"

	"github.com/asadlive84/fitness-care-bagerhat/internal/config"
	_ "github.com/lib/pq"
	"github.com/google/uuid"
	"golang.org/x/crypto/bcrypt"
)

func main() {
	name     := flag.String("name",     "",  "Admin full name (required)")
	email    := flag.String("email",    "",  "Admin email address (required)")
	phone    := flag.String("phone",    "",  "Admin phone number (optional)")
	password := flag.String("password", "",  "Admin password — min 8 chars (required)")
	flag.Parse()

	// ── Validate inputs ───────────────────────────────────────────────────────
	if *name == "" || *email == "" || *password == "" {
		fmt.Fprintln(os.Stderr, "Error: -name, -email, and -password are required")
		fmt.Fprintln(os.Stderr, "")
		fmt.Fprintln(os.Stderr, "Example:")
		fmt.Fprintln(os.Stderr, `  make seed/admin name="Gym Owner" email="owner@gym.bd" phone="01711000000" password="Admin@1234"`)
		os.Exit(1)
	}
	if len(*password) < 8 {
		fmt.Fprintln(os.Stderr, "Error: password must be at least 8 characters")
		os.Exit(1)
	}

	// ── Load config (reads .env) ──────────────────────────────────────────────
	cfg, err := config.Load()
	if err != nil {
		log.Fatalf("load config: %v", err)
	}

	// ── Connect to database ───────────────────────────────────────────────────
	db, err := sql.Open("postgres", cfg.Database.DSN)
	if err != nil {
		log.Fatalf("open db: %v", err)
	}
	defer db.Close()

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	if err := db.PingContext(ctx); err != nil {
		log.Fatalf("connect to database: %v\nMake sure Postgres is running (make docker/up)", err)
	}

	// ── Check for existing admin ──────────────────────────────────────────────
	var count int
	db.QueryRowContext(ctx, "SELECT COUNT(*) FROM admins WHERE email = $1", *email).Scan(&count)
	if count > 0 {
		fmt.Printf("⚠️  Admin with email %q already exists. Nothing created.\n", *email)
		os.Exit(0)
	}

	// ── Hash password ─────────────────────────────────────────────────────────
	hash, err := bcrypt.GenerateFromPassword([]byte(*password), 12)
	if err != nil {
		log.Fatalf("hash password: %v", err)
	}

	// ── Insert admin ──────────────────────────────────────────────────────────
	id := uuid.New()
	var phoneVal interface{} = nil
	if *phone != "" {
		phoneVal = *phone
	}

	_, err = db.ExecContext(ctx, `
		INSERT INTO admins (id, name, phone, email, password_hash, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, NOW(), NOW())
	`, id, *name, phoneVal, *email, string(hash))
	if err != nil {
		log.Fatalf("insert admin: %v", err)
	}

	// ── Done ──────────────────────────────────────────────────────────────────
	fmt.Println()
	fmt.Println("✅ Admin account created successfully!")
	fmt.Println()
	fmt.Printf("   ID     : %s\n", id)
	fmt.Printf("   Name   : %s\n", *name)
	fmt.Printf("   Email  : %s\n", *email)
	if *phone != "" {
		fmt.Printf("   Phone  : %s\n", *phone)
	}
	fmt.Println()
	fmt.Println("   Login at: POST /api/v1/auth/admin/login")
	fmt.Printf("   Body    : {\"email\":\"%s\",\"password\":\"<your-password>\"}\n", *email)
	fmt.Println()
}
