# frozen_string_literal: true

# Central auth configuration. JWT secret falls back to the app secret in dev/test;
# production should set JWT_SECRET_KEY explicitly.
module AuthConfig
  ACCESS_TOKEN_TTL = 15.minutes
  REFRESH_TOKEN_TTL = 30.days
  JWT_ALGORITHM = "HS256"

  def self.jwt_secret
    ENV.fetch("JWT_SECRET_KEY") { Rails.application.secret_key_base }
  end
end
