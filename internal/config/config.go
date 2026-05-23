package config

import (
	"fmt"
	"strings"
	"time"

	"github.com/spf13/viper"
)

// Config holds all application configuration loaded from environment / .env file.
type Config struct {
	App        AppConfig
	Database   DatabaseConfig
	Redis      RedisConfig
	JWT        JWTConfig
	CORS       CORSConfig
	FCM        FCMConfig
	Upload     UploadConfig
	AI         AIConfig
	SuperAdmin SuperAdminConfig
}

// SuperAdminConfig holds seed credentials for the superadmin account.
type SuperAdminConfig struct {
	Email    string // SUPERADMIN_EMAIL
	Password string // SUPERADMIN_PASSWORD
	ApiKey   string // SUPERADMIN_API_KEY
}

type UploadConfig struct {
	Dir       string
	MaxSizeMB int64
	S3Bucket  string
	S3Region  string
	S3BaseURL string // public base URL for uploaded files
}

type AIConfig struct {
	TextProvider   string // deepseek, openai, etc.
	VisionProvider string // gemini, openai, etc.
	TextAPIKey     string
	VisionAPIKey   string
}

// FCMConfig holds Firebase Cloud Messaging credentials.
type FCMConfig struct {
	ProjectID       string // Firebase project ID
	CredentialsJSON string // Service account JSON (may be empty for local dev)
}

type AppConfig struct {
	Env          string        // development | production
	Port         string        // :8080
	ReadTimeout  time.Duration // HTTP server read timeout
	WriteTimeout time.Duration // HTTP server write timeout
	Timezone     string        // Asia/Dhaka
}

type DatabaseConfig struct {
	DSN             string        // postgres://user:pass@host:5432/db?sslmode=disable
	MaxOpenConns    int
	MaxIdleConns    int
	ConnMaxLifetime time.Duration
}

type RedisConfig struct {
	Addr         string        // localhost:6379
	Password     string
	DB           int
	DialTimeout  time.Duration
	ReadTimeout  time.Duration
	WriteTimeout time.Duration
	PoolSize     int
}

type JWTConfig struct {
	AccessSecret  string
	RefreshSecret string
	AccessTTL     time.Duration // 15m
	RefreshTTL    time.Duration // 7d
}

type CORSConfig struct {
	AllowedOrigins []string
}

// Load reads configuration from environment variables (and optional .env file via viper).
func Load() (*Config, error) {
	viper.SetConfigFile(".env")
	viper.SetConfigType("env")
	viper.AutomaticEnv()

	// .env is optional — real env vars take precedence
	if err := viper.ReadInConfig(); err != nil {
		if !strings.Contains(err.Error(), "no such file") {
			return nil, fmt.Errorf("read config: %w", err)
		}
	}

	setDefaults()

	cfg := &Config{
		App: AppConfig{
			Env:          viper.GetString("APP_ENV"),
			Port:         viper.GetString("APP_PORT"),
			ReadTimeout:  viper.GetDuration("APP_READ_TIMEOUT"),
			WriteTimeout: viper.GetDuration("APP_WRITE_TIMEOUT"),
			Timezone:     viper.GetString("APP_TIMEZONE"),
		},
		Database: DatabaseConfig{
			DSN:             viper.GetString("DATABASE_DSN"),
			MaxOpenConns:    viper.GetInt("DB_MAX_OPEN_CONNS"),
			MaxIdleConns:    viper.GetInt("DB_MAX_IDLE_CONNS"),
			ConnMaxLifetime: viper.GetDuration("DB_CONN_MAX_LIFETIME"),
		},
		Redis: RedisConfig{
			Addr:         viper.GetString("REDIS_ADDR"),
			Password:     viper.GetString("REDIS_PASSWORD"),
			DB:           viper.GetInt("REDIS_DB"),
			DialTimeout:  viper.GetDuration("REDIS_DIAL_TIMEOUT"),
			ReadTimeout:  viper.GetDuration("REDIS_READ_TIMEOUT"),
			WriteTimeout: viper.GetDuration("REDIS_WRITE_TIMEOUT"),
			PoolSize:     viper.GetInt("REDIS_POOL_SIZE"),
		},
		JWT: JWTConfig{
			AccessSecret:  viper.GetString("JWT_ACCESS_SECRET"),
			RefreshSecret: viper.GetString("JWT_REFRESH_SECRET"),
			AccessTTL:     viper.GetDuration("JWT_ACCESS_TTL"),
			RefreshTTL:    viper.GetDuration("JWT_REFRESH_TTL"),
		},
		CORS: CORSConfig{
			AllowedOrigins: strings.Split(viper.GetString("CORS_ALLOWED_ORIGINS"), ","),
		},
		FCM: FCMConfig{
			ProjectID:       viper.GetString("FCM_PROJECT_ID"),
			CredentialsJSON: viper.GetString("FIREBASE_CREDENTIALS_JSON"),
		},
		Upload: UploadConfig{
			Dir:       viper.GetString("UPLOAD_DIR"),
			MaxSizeMB: viper.GetInt64("UPLOAD_MAX_SIZE_MB"),
			S3Bucket:  viper.GetString("S3_BUCKET"),
			S3Region:  viper.GetString("S3_REGION"),
			S3BaseURL: viper.GetString("S3_BASE_URL"),
		},
		AI: AIConfig{
			TextProvider:   viper.GetString("AI_TEXT_PROVIDER"),
			VisionProvider: viper.GetString("AI_VISION_PROVIDER"),
			TextAPIKey:     viper.GetString("AI_TEXT_API_KEY"),
			VisionAPIKey:   viper.GetString("AI_VISION_API_KEY"),
		},
		SuperAdmin: SuperAdminConfig{
			Email:    viper.GetString("SUPERADMIN_EMAIL"),
			Password: viper.GetString("SUPERADMIN_PASSWORD"),
			ApiKey:   viper.GetString("SUPERADMIN_API_KEY"),
		},
	}

	if err := validate(cfg); err != nil {
		return nil, err
	}

	return cfg, nil
}

func setDefaults() {
	viper.SetDefault("APP_ENV", "development")
	viper.SetDefault("APP_PORT", ":8080")
	viper.SetDefault("APP_READ_TIMEOUT", "10s")
	viper.SetDefault("APP_WRITE_TIMEOUT", "10s")
	viper.SetDefault("APP_TIMEZONE", "Asia/Dhaka")

	viper.SetDefault("DB_MAX_OPEN_CONNS", 25)
	viper.SetDefault("DB_MAX_IDLE_CONNS", 10)
	viper.SetDefault("DB_CONN_MAX_LIFETIME", "1h")

	viper.SetDefault("REDIS_ADDR", "localhost:6379")
	viper.SetDefault("REDIS_DB", 0)
	viper.SetDefault("REDIS_DIAL_TIMEOUT", "5s")
	viper.SetDefault("REDIS_READ_TIMEOUT", "200ms")
	viper.SetDefault("REDIS_WRITE_TIMEOUT", "200ms")
	viper.SetDefault("REDIS_POOL_SIZE", 10)

	viper.SetDefault("JWT_ACCESS_TTL", "15m")
	viper.SetDefault("JWT_REFRESH_TTL", "168h") // 7 days

	viper.SetDefault("UPLOAD_DIR", "./uploads")
	viper.SetDefault("UPLOAD_MAX_SIZE_MB", 5)

	viper.SetDefault("CORS_ALLOWED_ORIGINS", "http://localhost:5050,http://localhost:5000,http://localhost:3000")

	viper.SetDefault("AI_TEXT_PROVIDER", "deepseek")
	viper.SetDefault("AI_VISION_PROVIDER", "gemini")
	viper.SetDefault("SUPERADMIN_API_KEY", "superadmin_default_secret_key_123")
}

func validate(cfg *Config) error {
	if cfg.Database.DSN == "" {
		return fmt.Errorf("DATABASE_DSN is required")
	}
	if cfg.JWT.AccessSecret == "" {
		return fmt.Errorf("JWT_ACCESS_SECRET is required")
	}
	if cfg.JWT.RefreshSecret == "" {
		return fmt.Errorf("JWT_REFRESH_SECRET is required")
	}
	return nil
}
