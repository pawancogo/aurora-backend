# frozen_string_literal: true

redis_url = ENV.fetch("REDIS_URL", "redis://localhost:6379/0")

Sidekiq.configure_server do |config|
  config.redis = { url: redis_url }
end

Sidekiq.configure_client do |config|
  config.redis = { url: redis_url }
end

# NOTE: The Sidekiq::Web dashboard is intentionally deferred to Sprint 13 (Admin panel),
# where it will be mounted behind admin RBAC with a proper session. Mounting it in an
# API-only app now would require extra session/CSRF middleware for little Sprint 1 value.
