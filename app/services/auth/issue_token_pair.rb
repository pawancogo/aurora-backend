# frozen_string_literal: true

module Auth
  # Issues a short-lived access JWT plus a persisted (hashed) refresh token for an owner.
  class IssueTokenPair
    Result = Struct.new(:access_token, :refresh_token, :access_expires_in, keyword_init: true)

    def initialize(owner, user_agent: nil, ip_address: nil)
      @owner = owner
      @user_agent = user_agent
      @ip_address = ip_address
    end

    def call
      raw_refresh = SecureRandom.urlsafe_base64(48)

      @owner.refresh_tokens.create!(
        token_digest: TokenDigest.digest(raw_refresh),
        expires_at: AuthConfig::REFRESH_TOKEN_TTL.from_now,
        user_agent: @user_agent,
        ip_address: @ip_address
      )

      access = JsonWebToken.encode({ sub: @owner.id, typ: @owner.class.name })

      Result.new(
        access_token: access,
        refresh_token: raw_refresh,
        access_expires_in: AuthConfig::ACCESS_TOKEN_TTL.to_i
      )
    end
  end
end
