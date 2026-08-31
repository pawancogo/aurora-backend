# Aurora backend (Rails API)

Rails 8.1 API + server-rendered admin at `/admin`. This repo is independent of the [frontend](../frontend) (Next.js on port 3000). They talk only over HTTP.

| What | Where |
|------|--------|
| API | `http://localhost:3001/api/v1` |
| Admin portal | `http://localhost:3001/admin` |
| Super-admin console | `http://localhost:3001/superadmin` |
| Health | `GET /api/v1/health` · `GET /api/v1/ready` |

---

## What you need at the system level

Install these **before** `bundle install`. Versions match CI.

| Dependency | Version | Why |
|------------|---------|-----|
| **Git** | any recent | clone the repo |
| **Ruby** | **3.4.2** (see `.ruby-version`) | Rails |
| **Bundler** | 2.x | gems |
| **PostgreSQL** | **16** | primary database |
| **Redis** | **7** | Sidekiq jobs, readiness, cache |
| **libpq** | matching Postgres | compile the `pg` gem |
| **libvips** | recent | CarrierWave / `ruby-vips` image processing |
| **ImageMagick** | recent | CarrierWave / `mini_magick` |
| **C compiler / headers** | Xcode CLT or `build-essential` | native gems (`pg`, `bcrypt`, `sassc`, …) |

Optional: **Docker + Compose** if you would rather not install Postgres/Redis on the host. Native processes are what this project is verified against day to day.

You do **not** need Elasticsearch.

### macOS (Homebrew)

```bash
xcode-select --install   # once, if `gcc` is missing

brew install rbenv ruby-build
brew install postgresql@16 redis libpq vips imagemagick
brew services start postgresql@16
brew services start redis

# so the `pg` gem can find `pg_config`
echo 'export PATH="$(brew --prefix libpq)/bin:$PATH"' >> ~/.zshrc
echo 'eval "$(rbenv init - zsh)"' >> ~/.zshrc
source ~/.zshrc

rbenv install 3.4.2
rbenv global 3.4.2
gem install bundler
```

If Homebrew Postgres uses your macOS username and no password (the default), you are done. Create the databases on first setup with `bin/rails db:prepare` below — Rails will create `ecom_development` / `ecom_test` if they are missing.

Confirm:

```bash
ruby -v          # ruby 3.4.2
psql --version   # 16.x
redis-cli ping   # PONG
```

### Ubuntu / Debian

```bash
sudo apt-get update
sudo apt-get install -y git build-essential libpq-dev libvips-dev imagemagick \
  postgresql postgresql-contrib redis-server

# Ruby 3.4.2 via rbenv (or asdf)
curl -fsSL https://github.com/rbenv/rbenv-installer/raw/main/bin/rbenv-installer | bash
# then: rbenv install 3.4.2 && rbenv global 3.4.2 && gem install bundler

sudo systemctl enable --now postgresql redis-server
sudo -u postgres createuser -s "$USER"
```

---

## One-time repo setup

From this directory (`backend/`):

```bash
cp .env.example .env
bundle install
bin/rails db:prepare    # create DB + migrate + seed
```

`db:prepare` on a **new** database also runs `db/seeds.rb` (catalog, RBAC, demo customer, roadmap). On an existing database, migrate and re-seed yourself:

```bash
bin/rails db:migrate
bin/rails db:seed
bin/rails runner 'load Rails.root.join("db/seeds/roadmap.rb")'
```

### `.env` (required vs optional)

| Variable | Required locally? | Default / notes |
|----------|-------------------|-----------------|
| `REDIS_URL` | yes (copy from example) | `redis://localhost:6379/0` |
| `FRONTEND_ORIGIN` | yes | `http://localhost:3000` — **must** match the origin in the browser (CORS does not allow `http://127.0.0.1:3000`) |
| `DATABASE_HOST` / `USERNAME` / `PASSWORD` | only if not using peer/ident | otherwise Rails uses `localhost` + your OS user, empty password |
| `DATABASE_URL` | only for Docker/CI | overrides host/user/password |
| `RAZORPAY_KEY_ID` / `RAZORPAY_KEY_SECRET` | for checkout | without these, placing an order fails with “Payments are not configured yet” |
| `RAZORPAY_WEBHOOK_SECRET` | for webhook verify | optional in local UI checkout |
| `SMTP_ADDRESS` (+ user/password) | no | unset → mail is written to `tmp/mails/` |
| `MAIL_FROM` | no | `no-reply@aurora.test` |
| `STORAGE_PROVIDER` | no | `local` → `public/uploads` |

Never commit `.env`.

### Seeded logins (after `db:seed`)

| Who | URL | Email | Password |
|-----|-----|-------|----------|
| Shopper | frontend `:3000` | `demo@aurora.test` | `Password123!` |
| Admin | `/admin` | `superadmin@aurora.test` | `ChangeMe123!` |

Override with `SEED_CUSTOMER_EMAIL` / `SEED_ADMIN_EMAIL` (and matching `*_PASSWORD`) before seeding.

---

## What to start, and in what order

Keep these running the whole time you develop. **Postgres and Redis first** — Rails and Sidekiq will not boot usefully without them.

Open **four terminals** from `backend/` (plus one later in `frontend/`).

### 1. PostgreSQL

```bash
# macOS Homebrew
brew services start postgresql@16

# or if you installed a generic `postgresql` formula
brew services start postgresql
```

Linux: `sudo systemctl start postgresql`.

### 2. Redis

```bash
brew services start redis
# or a one-shot process:
redis-server
```

Check: `redis-cli ping` → `PONG`.

### 3. Rails API (port **3001**)

```bash
bin/rails server
# equivalent: bundle exec rails s
```

Puma is configured for **3001** so it does not collide with Next.js on 3000. Do not use `-p 3000`.

Smoke test: `curl -s http://localhost:3001/api/v1/health`

Admin: [http://localhost:3001/admin/login](http://localhost:3001/admin/login)

### 4. Sidekiq (background jobs)

Email (verify, reset, order notifications) is `deliver_later` / `Notifications::DeliverJob` on the **default** queue. Without Sidekiq those jobs sit in Redis.

```bash
bundle exec sidekiq
```

Start this **after** Redis. If Redis is down, checkout still places the order, but notification email falls back to sending inline (slower request).

### 5. Frontend (separate repo, port **3000**)

Only after the API is up:

```bash
cd ../frontend
cp .env.example .env.local   # once
pnpm install                 # once; Node 24, see frontend README
pnpm dev
```

Storefront: [http://localhost:3000](http://localhost:3000) — use **localhost**, not `127.0.0.1`.

### Daily restart order (short)

```text
1. PostgreSQL
2. Redis
3. bin/rails server          → :3001
4. bundle exec sidekiq
5. (frontend) pnpm dev       → :3000
```

Stop with Ctrl-C in each terminal. `brew services` Postgres/Redis can stay running.

---

## Tests and lint

```bash
bundle exec rspec
bundle exec rubocop
bundle exec brakeman -q --no-pager
```

RSpec needs Postgres **and** Redis (`/api/v1/ready` talks to Redis).

---

## Docker Compose (optional)

From `backend/`:

```bash
docker compose up --build
```

Brings up Postgres, Redis, the API on `:3001`, and Sidekiq. Point `.env` / Compose at `DATABASE_URL=postgres://ecom:ecom@db:5432/ecom_development`. The frontend still runs from its own repo (or `frontend/docker-compose.yml`). Compose is authored for this layout; native processes are the verified local path.

---

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| `pg` gem fails to install | `brew install libpq` and put `$(brew --prefix libpq)/bin` on `PATH` |
| `connection refused 5432` | start Postgres; or set `DATABASE_HOST` / `DATABASE_URL` |
| `RedisClient::CannotConnectError` / `/api/v1/ready` 503 | `brew services start redis` |
| Checkout: “Payments are not configured yet” | set `RAZORPAY_KEY_ID` and `RAZORPAY_KEY_SECRET` in `.env`, restart Rails |
| Browser CORS / empty storefront | open `http://localhost:3000`, not `http://127.0.0.1:3000` |
| No verification / order emails | start Sidekiq; or inspect `tmp/mails/` if SMTP is unset |
| Admin login loop | use `/admin/login` on **3001**, not the Next.js origin |
