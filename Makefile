.PHONY: run build test tidy lint migrate-up migrate-down migrate-create \
        docker-up docker-down docker-logs sqlc swagger

# ── Config ────────────────────────────────────────────────────────────────────
BINARY      := ./bin/server
MAIN        := ./cmd/api
MIGRATE_DSN ?= $(shell grep DATABASE_DSN .env 2>/dev/null | cut -d= -f2-)
MIGRATIONS  := ./migrations

# ── Development ───────────────────────────────────────────────────────────────

## seed/admin: create the gym owner admin account (run once after first migrate)
## Usage: make seed/admin name="Gym Owner" email="asad@me.com" phone="01711000000" password="Admin@1234"
seed/admin:
	go run ./cmd/seed \
		-name="$(name)" \
		-email="$(email)" \
		-phone="$(phone)" \
		-password="$(password)"

## run: run the API server locally (requires .env)
run:
	go run $(MAIN)/main.go

## build: compile the binary to ./bin/server
build:
	@mkdir -p bin
	CGO_ENABLED=0 go build -ldflags="-s -w" -o $(BINARY) $(MAIN)

## test: run all tests with race detector
test:
	go test -race -count=1 ./...

## test/cover: run tests and open HTML coverage report
test/cover:
	go test -race -count=1 -coverprofile=coverage.out ./...
	go tool cover -html=coverage.out

## tidy: tidy and verify go.mod
tidy:
	go mod tidy
	go mod verify

## lint: run golangci-lint (install separately: brew install golangci-lint)
lint:
	golangci-lint run ./...

# ── Docker ────────────────────────────────────────────────────────────────────

## up: ONE COMMAND — build image, run migrations, start full stack
up:
	docker compose up --build

## up/detach: same as `up` but runs in the background
up/detach:
	docker compose up --build -d

## down: stop and remove all containers + networks
down:
	docker compose down

## down/clean: stop containers AND delete volumes (wipes DB data)
down/clean:
	docker compose down -v

## docker/up: start only Postgres + Redis (for local `make run`)
docker/up:
	docker compose up -d postgres redis

## docker/logs: tail application logs
docker/logs:
	docker compose logs -f app

## docker/migrate: run migrations only (useful after schema changes)
docker/migrate:
	docker compose run --rm migrate

# ── Database migrations ───────────────────────────────────────────────────────

## migrate/up: apply all pending migrations
migrate/up:
	migrate -path $(MIGRATIONS) -database "$(MIGRATE_DSN)" up

## migrate/down: roll back the last migration
migrate/down:
	migrate -path $(MIGRATIONS) -database "$(MIGRATE_DSN)" down 1

## migrate/create name=<name>: create a new migration pair
migrate/create:
	migrate create -ext sql -dir $(MIGRATIONS) -seq $(name)

## migrate/status: show migration status
migrate/status:
	migrate -path $(MIGRATIONS) -database "$(MIGRATE_DSN)" version

# ── Code generation ───────────────────────────────────────────────────────────

## sqlc: regenerate type-safe DB code from SQL queries
sqlc:
	sqlc generate

## swagger: regenerate Swagger docs (requires swag: go install github.com/swaggo/swag/cmd/swag@latest)
swagger:
	swag init -g cmd/api/main.go -o docs

# ── Mobile ────────────────────────────────────────────────────────────────────

## mobile: build and run the Flutter app on the emulator
mobile:
	cd mobile_app && /Users/asad/development/flutter/bin/flutter pub run build_runner build --delete-conflicting-outputs && /Users/asad/development/flutter/bin/flutter run -d emulator-5554

# ── Help ──────────────────────────────────────────────────────────────────────

## help: list available make targets
help:
	@grep -E '^##' Makefile | sed 's/## //'

apk:
	cd mobile_app && flutter build apk --release
	cp mobile_app/build/app/outputs/flutter-apk/app-release.apk fitnessCareBagerhat.apk
	@echo "APK ready → fitnessCareBagerhat.apk"

ipa:
	cd mobile_app && flutter build ipa --release --no-codesign
	mkdir -p /tmp/ipa_build/Payload
	cp -r mobile_app/build/ios/archive/Runner.xcarchive/Products/Applications/Runner.app /tmp/ipa_build/Payload/
	cd /tmp/ipa_build && zip -r fitnessCareBagerhat.ipa Payload
	cp /tmp/ipa_build/fitnessCareBagerhat.ipa ./fitnessCareBagerhat.ipa
	rm -rf /tmp/ipa_build
	@echo "IPA ready → fitnessCareBagerhat.ipa"


mobile_app:
	flutter run -d emulator-5554;