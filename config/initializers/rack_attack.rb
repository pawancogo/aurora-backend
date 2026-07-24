# frozen_string_literal: true

# Baseline request throttling. Stricter, auth-specific limits are layered on in Sprint 2.
class Rack::Attack
  # Shared, Redis-backed store so limits hold across all app processes.
  Rack::Attack.cache.store = ActiveSupport::Cache::RedisCacheStore.new(
    url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0")
  )

  # General throttle: 300 requests / 5 minutes per IP. Health probes are exempt.
  throttle("req/ip", limit: 300, period: 5.minutes) do |req|
    req.ip unless req.path.start_with?("/up", "/api/v1/health", "/api/v1/ready")
  end

  # Stricter, auth-specific limits (brute-force / abuse protection).
  throttle("customer_login/ip", limit: 10, period: 1.minute) do |req|
    req.ip if req.post? && req.path == "/api/v1/customer/auth/login"
  end

  throttle("admin_login/ip", limit: 10, period: 1.minute) do |req|
    req.ip if req.post? && req.path == "/api/v1/admin/auth/login"
  end

  throttle("register/ip", limit: 5, period: 1.minute) do |req|
    req.ip if req.post? && req.path == "/api/v1/customer/auth/register"
  end

  throttle("password_reset/ip", limit: 5, period: 1.hour) do |req|
    req.ip if req.post? && req.path == "/api/v1/customer/auth/forgot-password"
  end

  # Token brute-force: submitting reset / verification tokens.
  throttle("password_update/ip", limit: 10, period: 1.hour) do |req|
    req.ip if req.post? && req.path == "/api/v1/customer/auth/reset-password"
  end

  throttle("email_verification/ip", limit: 10, period: 1.hour) do |req|
    req.ip if req.post? &&
              %w[/api/v1/customer/auth/verify-email /api/v1/customer/auth/resend-verification].include?(req.path)
  end

  # Server-rendered admin portal (session) login — brute-force protection.
  throttle("admin_portal_login/ip", limit: 10, period: 1.minute) do |req|
    req.ip if req.post? && req.path == "/admin/login"
  end

  # Admin media uploads — abuse / storage-fill protection.
  throttle("admin_uploads/ip", limit: 60, period: 1.minute) do |req|
    req.ip if req.post? && req.path == "/admin/uploads"
  end
end

# Respond to throttled requests with the standard JSON error envelope.
Rack::Attack.throttled_responder = lambda do |request|
  match_data = request.env["rack.attack.match_data"] || {}
  headers = {
    "Content-Type" => "application/json",
    "Retry-After" => match_data[:period].to_s
  }
  body = { error: { code: "rate_limited", message: "Too many requests. Please retry later." } }
  [ 429, headers, [ body.to_json ] ]
end

# Register the middleware.
Rails.application.config.middleware.use Rack::Attack

# Disabled in the test suite so shared throttle counters don't make specs flaky.
Rack::Attack.enabled = false if Rails.env.test?
