# frozen_string_literal: true

# Fail fast in production when critical configuration is missing; warn (don't crash) in
# development. Named "00_" so it runs before initializers that read these values.
module EnvironmentValidator
  # Hard requirements in production.
  PRODUCTION_REQUIRED = %w[DATABASE_URL REDIS_URL FRONTEND_ORIGIN SECRET_KEY_BASE].freeze
  # Values the app actively relies on in development (DB + secret are auto-managed by Rails).
  DEVELOPMENT_REQUIRED = %w[REDIS_URL FRONTEND_ORIGIN].freeze

  def self.validate!
    return if Rails.env.test? # test config comes from CI env / defaults

    required = Rails.env.production? ? PRODUCTION_REQUIRED : DEVELOPMENT_REQUIRED
    missing = required.select { |key| ENV[key].to_s.strip.empty? }
    return if missing.empty?

    message = "Missing required environment variables: #{missing.join(', ')}"
    raise message if Rails.env.production?

    warn "[EnvironmentValidator] #{message} (tolerated in #{Rails.env})"
  end
end

EnvironmentValidator.validate!
