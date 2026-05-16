# ── Build stage ───────────────────────────────────────────────────────────────
FROM golang:1.25-alpine AS builder

# Install git for go mod download of private deps (if any)
RUN apk add --no-cache git

WORKDIR /app

# Cache dependency layer — only re-fetched when go.mod/go.sum change.
COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux go build \
    -ldflags="-s -w" \
    -o /app/server \
    ./cmd/api

# ── Runtime stage ─────────────────────────────────────────────────────────────
# Using scratch for minimal attack surface.
# time/tzdata is embedded in the binary via _ "time/tzdata" import,
# so no /usr/share/zoneinfo is needed in the container.
FROM scratch

COPY --from=builder /app/server /server
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

EXPOSE 8080

ENTRYPOINT ["/server"]
