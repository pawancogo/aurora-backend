# frozen_string_literal: true

module Auth
  # Validates a raw refresh token, revokes it, and issues a fresh pair (rotation).
  # Rotation + revocation happen atomically so a token can never be reused.
  class RotateRefreshToken
    class InvalidToken < StandardError; end

    Rotation = Struct.new(:owner, :tokens, keyword_init: true)

    def initialize(raw_token, owner_class:, user_agent: nil, ip_address: nil)
      @raw = raw_token.to_s
      @owner_class = owner_class
      @user_agent = user_agent
      @ip_address = ip_address
    end

    def call
      token = RefreshToken.active
                          .where(owner_type: @owner_class.name)
                          .find_by(token_digest: TokenDigest.digest(@raw))
      raise InvalidToken, "Invalid or expired refresh token" unless token

      owner = token.owner
      raise InvalidToken, "Account is not active" unless owner&.active_for_auth?

      tokens = nil
      RefreshToken.transaction do
        token.revoke!
        tokens = IssueTokenPair.new(owner, user_agent: @user_agent, ip_address: @ip_address).call
      end

      Rotation.new(owner: owner, tokens: tokens)
    end
  end
end
