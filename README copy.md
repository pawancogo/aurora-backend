# Enterprise E-Commerce Platform

Two **independent applications**, grouped in this folder only for local convenience.
Each is its own git repository with its own Docker, CI, gitignore, and scripts — they
share no source and communicate only over HTTP.

```
ecomWebApp/            (plain folder — NOT a repo)
├── backend/           independent repo · Rails 8.1 API
├── frontend/          independent repo · Next.js 16 storefront
├── ROADMAP.md         canonical 17-sprint plan
├── PROJECT_STATE.md   living status + architecture decisions
└── SPRINT_PLAN.md     superseded (kept for history)
```

## backend/ — Rails 8.1 API

PostgreSQL · Redis · Sidekiq · RSpec · Pundit · Rack::Attack. Customer APIs under `/api/v1`.
Self-contained: `Dockerfile`, `docker-compose.yml`, `.github/workflows/ci.yml`, `scripts/dev.sh`.

```bash
cd backend
# Docker (db, redis, api, sidekiq):
docker compose up --build
# or native (needs local PostgreSQL):
bundle install && bin/rails db:prepare && ./scripts/dev.sh
# → http://localhost:3001/api/v1/health
```

## frontend/ — Next.js 16 storefront

TypeScript · Tailwind v4 · shadcn/ui · TanStack Query · React Hook Form · Zod · Axios · Framer Motion · Vitest.
Self-contained: `Dockerfile`, `docker-compose.yml`, `.github/workflows/ci.yml`, `scripts/dev.sh`.
Expects the API on `:3001`.

```bash
cd frontend
pnpm install
pnpm dev            # → http://localhost:3000
# or Docker: docker compose up --build
```

**Toolchain:** Ruby 3.4.2 (`backend/.ruby-version`) · Node 24 (`frontend/.nvmrc`) · pnpm.

## API contract

All endpoints are versioned under `/api/v1` and return a consistent envelope:

```jsonc
// success
{ "data": { /* ... */ }, "meta": { /* optional */ } }
// error
{ "error": { "code": "string", "message": "human readable", "details": {} } }
```
