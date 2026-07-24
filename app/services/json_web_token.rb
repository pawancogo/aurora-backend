# frozen_string_literal: true

# Thin wrapper around the jwt gem for encoding/decoding access tokens.
class JsonWebToken
  class DecodeError < StandardError; end

  def self.encode(payload, exp: AuthConfig::ACCESS_TOKEN_TTL.from_now)
    claims = payload.merge(exp: exp.to_i)
    JWT.encode(claims, AuthConfig.jwt_secret, AuthConfig::JWT_ALGORITHM)
  end

  def self.decode(token)
    payload, = JWT.decode(token, AuthConfig.jwt_secret, true, algorithm: AuthConfig::JWT_ALGORITHM)
    payload.with_indifferent_access
  rescue JWT::DecodeError => e
    raise DecodeError, e.message
  end
end
