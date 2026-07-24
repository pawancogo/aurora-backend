# frozen_string_literal: true

require "connection_pool"
require "redis"

# Shared, thread-safe Redis connection pool used by readiness checks today and
# application caching in later sprints. Sidekiq maintains its own separate pool.
REDIS_POOL = ConnectionPool.new(size: ENV.fetch("RAILS_MAX_THREADS", 5).to_i, timeout: 1) do
  Redis.new(url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0"))
end
