# ── Build stage ───────────────────────────────────────────────────────────────
FROM node:20-alpine AS builder

WORKDIR /app

# Cache dependency install layer
COPY package*.json ./
RUN npm install --legacy-peer-deps --no-audit

COPY . .

# NEXT_PUBLIC_API_URL is embedded at build time for client-side code.
# The browser calls the API directly on the mapped host port (9000).
# Override with --build-arg NEXT_PUBLIC_API_URL=https://your-api.example.com
ARG NEXT_PUBLIC_API_URL=http://localhost:9000
ENV NEXT_PUBLIC_API_URL=$NEXT_PUBLIC_API_URL

RUN npm run build

# ── Runtime stage ─────────────────────────────────────────────────────────────
FROM node:20-alpine AS runner

WORKDIR /app

ENV NODE_ENV=production
ENV PORT=3000

# Copy standalone Next.js output
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static     ./.next/static
COPY --from=builder /app/public           ./public

EXPOSE 3000

CMD ["node", "server.js"]
