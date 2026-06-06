# Fitness Care Bagerhat — Gym Management API


### Note: This app fullly learning purpose and this application for my little brother Gym. you can use this app fully free however you have to use own server

Production-grade REST API for a single-gym management system in Bagerhat, Bangladesh.  
Built with Go, Fiber v2, PostgreSQL, and Redis.

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Prerequisites](#prerequisites)
3. [Quick Start](#quick-start)
4. [Environment Variables](#environment-variables)
5. [API Endpoints](#api-endpoints)
6. [Running Tests](#running-tests)
7. [Swagger Docs](#swagger-docs)
8. [Folder Structure](#folder-structure)
9. [Architecture](#architecture)

---

## Project Overview

Two roles:

| Role | Description |
|---|---|
| **Admin** | Gym owner — full control over members, plans, payments, messages, settings |
| **Member** | Gym customer — logs weight/workout/diet, views plan status, chats with admin |

**Currency:** BDT (Bangladeshi Taka)  
**Payment methods:** Cash, bKash, Nagad, Card  
**Timezone:** Asia/Dhaka

---

## Prerequisites

| Tool | Version | Notes |
|---|---|---|
| Go | 1.22+ | |
| PostgreSQL | 15+ | |
| Redis | 7+ | |
| Docker + Compose | Latest | for local dev |
| `golang-migrate` CLI | Latest | `brew install golang-migrate` |
| `swag` CLI | Latest | `go install github.com/swaggo/swag/cmd/swag@latest` |

---

## Quick Start

```bash
# 1. Clone the repository
git clone https://github.com/asadlive84/fitness-care-bagerhat.git
cd fitness-care-bagerhat

# 2. Start Postgres + Redis
make docker/up

# 3. Configure environment
cp .env.example .env
# Edit .env — set JWT secrets (required), FCM credentials (optional)

# 4. Run database migrations
make migrate/up

# 5. Start the server
make run
# API is now available at http://localhost:8080
# Swagger UI at   http://localhost:8080/swagger/index.html
```

### Full Docker stack (app + db + redis)

```bash
cp .env.example .env
# Edit .env for JWT secrets
docker compose up --build
```

---

## Environment Variables

| Variable | Required | Default | Description |
|---|---|---|---|
| `APP_ENV` | No | `development` | `development` or `production` |
| `APP_PORT` | No | `:8080` | HTTP listen address |
| `APP_TIMEZONE` | No | `Asia/Dhaka` | Scheduler timezone |
| `DATABASE_DSN` | **Yes** | — | Postgres connection string |
| `DB_MAX_OPEN_CONNS` | No | `25` | |
| `DB_MAX_IDLE_CONNS` | No | `10` | |
| `DB_CONN_MAX_LIFETIME` | No | `1h` | |
| `REDIS_ADDR` | No | `localhost:6379` | |
| `REDIS_PASSWORD` | No | — | |
| `REDIS_DB` | No | `0` | |
| `JWT_ACCESS_SECRET` | **Yes** | — | Min 32 chars |
| `JWT_REFRESH_SECRET` | **Yes** | — | Min 32 chars |
| `JWT_ACCESS_TTL` | No | `15m` | |
| `JWT_REFRESH_TTL` | No | `168h` | 7 days |
| `FCM_PROJECT_ID` | No | — | Firebase project ID |
| `FIREBASE_CREDENTIALS_JSON` | No | — | Service account JSON string |
| `CORS_ALLOWED_ORIGINS` | No | — | Comma-separated origins |

---

## API Endpoints

Interactive docs: **`GET /swagger/index.html`**

### Authentication

| Method | Path | Description | Auth |
|---|---|---|---|
| POST | `/api/v1/auth/admin/login` | Admin login → access + refresh tokens | — |
| POST | `/api/v1/auth/member/login` | Member login → tokens + `must_change_password` flag | — |
| POST | `/api/v1/auth/refresh` | Exchange refresh token for new pair | — |
| POST | `/api/v1/auth/change-password` | Member changes their password | Member |

> Auth routes are rate-limited: **10 requests / minute / IP**

### Admin — Members

| Method | Path | Description |
|---|---|---|
| POST | `/api/v1/admin/members` | Create member (returns one-time temp password) |
| GET | `/api/v1/admin/members` | List members (`?page&limit&status&search&expiring_soon`) |
| GET | `/api/v1/admin/members/:id` | Get member by ID |
| PATCH | `/api/v1/admin/members/:id` | Update member profile |
| PATCH | `/api/v1/admin/members/:id/status` | Activate / deactivate member |

### Admin — Plans

| Method | Path | Description |
|---|---|---|
| POST | `/api/v1/admin/plans` | Create plan template |
| GET | `/api/v1/admin/plans` | List all plans (Redis-cached 24 h) |
| PATCH | `/api/v1/admin/plans/:id` | Update plan |
| DELETE | `/api/v1/admin/plans/:id` | Delete plan (409 if active subscriptions exist) |

### Admin — Subscriptions

| Method | Path | Description |
|---|---|---|
| POST | `/api/v1/admin/members/:id/subscriptions` | Assign plan (replaces current active) |
| GET | `/api/v1/admin/members/:id/subscriptions` | Full subscription history |
| PATCH | `/api/v1/admin/members/:id/subscriptions/active` | Update active sub (price, end date, note) |

### Admin — Payments

| Method | Path | Description |
|---|---|---|
| POST | `/api/v1/admin/payments` | Record a payment |
| GET | `/api/v1/admin/members/:id/payments` | Member payment history (`?from&to` date range) |
| GET | `/api/v1/admin/payments/summary` | Monthly revenue (`?month=2026-05`) |

### Admin — Messages

| Method | Path | Description |
|---|---|---|
| POST | `/api/v1/admin/messages/broadcast` | Broadcast to all/active/expired/expiring members |
| POST | `/api/v1/admin/messages/direct` | Direct message to a member |
| GET | `/api/v1/admin/messages/conversations` | All conversations, newest first |
| GET | `/api/v1/admin/messages/conversations/:member_id` | Full conversation thread (marks read) |

### Admin — Settings

| Method | Path | Description |
|---|---|---|
| GET | `/api/v1/admin/settings` | Get all settings (Redis-cached 24 h) |
| PATCH | `/api/v1/admin/settings` | Create/update a setting (`{key, value}`) |

> Built-in keys: `quiet_window`, `nudge_days`, `weight_reminder_days`

### Member — Profile & Payments

| Method | Path | Description |
|---|---|---|
| GET | `/api/v1/member/profile` | Own profile |
| PATCH | `/api/v1/member/profile` | Update name, goal, current weight |
| GET | `/api/v1/member/subscription` | Active subscription |
| GET | `/api/v1/member/payments` | Own payment history (`?from&to`) |

### Member — Logs

| Method | Path | Description |
|---|---|---|
| POST | `/api/v1/member/weight-logs` | Log weight (`weight_kg`, optional `logged_at`) |
| GET | `/api/v1/member/weight-logs` | Weight history (`?from&to` date range) |
| POST | `/api/v1/member/workout-logs` | Log workout |
| GET | `/api/v1/member/workout-logs` | Workout history (paginated) |
| POST | `/api/v1/member/diet-logs` | Log diet |
| GET | `/api/v1/member/diet-logs` | Diet history (paginated) |

### Member — Messages & Notifications

| Method | Path | Description |
|---|---|---|
| GET | `/api/v1/member/messages` | All messages (direct + broadcasts, paginated) |
| POST | `/api/v1/member/messages` | Send message to admin |
| POST | `/api/v1/member/fcm-token` | Register / refresh FCM device token |
| PATCH | `/api/v1/member/notifications/mute` | Mute / unmute push notifications |

### Health

| Method | Path | Description |
|---|---|---|
| GET | `/healthz` | Liveness — always 200 if process is alive |
| GET | `/readyz` | Readiness — checks Postgres (503) + Redis (degraded 200) |

---

## Running Tests

```bash
# All tests (unit + cache integration — Redis must be running)
make test

# With coverage report (opens browser)
make test/cover

# DB integration tests (Postgres required on port 5433)
docker run -d --name fc_pg \
  -e POSTGRES_USER=gym -e POSTGRES_PASSWORD=gym_secret \
  -e POSTGRES_DB=fitnesscare -p 5433:5432 postgres:15-alpine

DATABASE_TEST_DSN="postgres://gym:gym_secret@localhost:5433/fitnesscare?sslmode=disable" \
  go test ./internal/database/... -v

docker rm -f fc_pg
```

### Test coverage by package

| Package | Tests | What's covered |
|---|---|---|
| `internal/cache` | 3 | Redis client: miss, set/get/delete, JSON round-trip |
| `internal/database` | 2 | Migration apply + sqlc CRUD (admin, member, plan, settings) |
| `internal/handlers` | 48 | Every handler: success, validation, 404, 409, auth |
| `internal/notifier` | 7 | Quiet window: cross-midnight, daytime, bad config, WindowEnd |
| `internal/repositories/cached` | 5 | Cache-aside: miss→DB, hit→skip DB, invalidation, credentials never cached |
| `internal/server` | 1 | /healthz 200 |
| `internal/services` | 9 | Auth: login success/fail, inactive, refresh, token type enforcement |

---

## Swagger Docs

```bash
# Regenerate after changing handler annotations
make swagger

# Browse at runtime
open http://localhost:8080/swagger/index.html
```

The Swagger JSON is also available at `/swagger/doc.json`.

---

## Folder Structure

```
fitness-care-bagerhat/
├── cmd/api/main.go              # Entry point: DI wiring, Fiber setup, graceful shutdown
├── docs/                        # Generated Swagger docs (committed)
├── migrations/
│   ├── 000001_initial_schema.up.sql   # All 13 tables + indexes + default settings
│   └── 000001_initial_schema.down.sql
├── internal/
│   ├── auth/jwt.go              # JWT Manager — HS256, access + refresh tokens, rotation
│   ├── cache/redis.go           # Redis client wrapper (200 ms timeout, JSON helpers)
│   ├── config/config.go         # Viper config — env + .env file, validated on startup
│   ├── database/
│   │   ├── db.go                # sql.DB pool
│   │   ├── queries/             # .sql files (sqlc input)
│   │   └── sqlc/                # Generated type-safe Go code (DO NOT EDIT)
│   ├── handlers/                # HTTP handlers — one file per feature domain
│   ├── logger/
│   │   ├── logger.go            # slog — JSON (prod) or text (dev) to stdout
│   │   └── db_sink.go           # Async io.Writer → system_logs table (2 s / 100 entries)
│   ├── middleware/
│   │   ├── auth.go              # RequireAuth (JWT) + RequireRole
│   │   ├── request_id.go        # UUID v4 per request, propagated via context
│   │   └── request_logger.go    # Structured request log (method, path, status, latency)
│   ├── models/                  # Domain structs (service layer DTOs)
│   ├── notifier/
│   │   ├── fcm.go               # FCM HTTP v1 via oauth2 service account
│   │   ├── noop.go              # Logs instead of sending (local dev / no credentials)
│   │   └── quiet_window.go      # IsInQuietWindow + WindowEnd (cross-midnight aware)
│   ├── repositories/
│   │   ├── repository.go        # All repository interfaces (consumer-side)
│   │   ├── errors.go            # ErrNotFound, ErrConflict, ErrFKViolation sentinels
│   │   ├── postgres/            # Pure DB implementations (no cache awareness)
│   │   └── cached/              # Decorator: Redis-first, falls back to postgres
│   ├── scheduler/scheduler.go   # 3 cron jobs: renewal (9AM), weight (8AM), dispatch (1min)
│   ├── server/health.go         # /healthz + /readyz handlers
│   ├── services/                # Business logic layer
│   └── utils/response.go        # SuccessResponse / PaginatedResponse / ErrorResponse
├── .env.example
├── docker-compose.yml
├── Dockerfile
├── Makefile
├── sqlc.yaml
└── go.mod
```

---

## Architecture

```
HTTP Request
    │
    ▼
[Fiber Middleware]          request_id • request_logger • RequireAuth • RequireRole
    │
    ▼
[Handler]                  parse + validate → call service
    │
    ▼
[Service]                  business logic, sentinel errors
    │
    ▼
[CachedRepository]         Redis GET → hit: return | miss: → PostgresRepo → SET with TTL
    │                       On write: PostgresRepo first → then invalidate Redis
    ▼
[PostgresRepository]       sqlc parameterised queries → PostgreSQL 15
```

### Cache strategy

| Entity | Key | TTL | Invalidated by |
|---|---|---|---|
| Member by ID | `member:{id}` | 1 h | Update, UpdateStatus, UpdatePassword |
| Member by phone | `member:phone:{phone}` | 1 h | Update |
| Active subscription | `member:{id}:subscription:active` | 1 h | Create, UpdateActive, ReplaceActive |
| All plan templates | `plans:all` | 24 h | Create, Update, Delete |
| All settings | `settings:all` | 24 h | Upsert |

Members list, payments, weight/workout/diet logs, messages and notifications are **never cached** — too many filter combinations, financial accuracy, or near-realtime requirements.

### Scheduler jobs

| Job | Schedule | Action |
|---|---|---|
| Renewal reminder | 09:00 Asia/Dhaka | Find expiring subscriptions → enqueue `renewal` notifications |
| Weight reminder | 08:00 Asia/Dhaka | Find members with no recent weight log → enqueue `weight_reminder` notifications |
| Notification dispatch | Every 1 minute | Drain pending notifications → check quiet window → send via FCM → mark sent/failed |

### Quiet window

Before sending any FCM push notification, the scheduler converts the current time to `Asia/Dhaka` and checks the `quiet_window` setting (`{"start":"22:00","end":"07:00"}`). If the notification falls inside the window, `scheduled_at` is moved to the window end time instead of sending immediately.

---

*Generated with Claude Code*
