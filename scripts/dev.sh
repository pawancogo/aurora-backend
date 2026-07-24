#!/usr/bin/env bash
# Start the backend natively (no Docker): Redis, Rails API, and Sidekiq.
# Ctrl-C stops everything. Requires local PostgreSQL.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
pids=()

cleanup() {
  echo ""
  echo "Shutting down..."
  for pid in "${pids[@]}"; do kill "$pid" 2>/dev/null || true; done
}
trap cleanup EXIT INT TERM

if ! redis-cli ping >/dev/null 2>&1; then
  echo "Starting redis-server..."
  redis-server & pids+=("$!")
fi

echo "Starting Rails API on :3001..."
(cd "$ROOT" && bin/rails server -p 3001) & pids+=("$!")

echo "Starting Sidekiq..."
(cd "$ROOT" && bundle exec sidekiq) & pids+=("$!")

wait
