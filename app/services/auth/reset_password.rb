# frozen_string_literal: true

module Auth
  # Sets a new password from a valid reset token and revokes all active sessions.
  class ResetPassword
    class InvalidToken < StandardError; end

    RESET_TTL = 2.hours

    def initialize(token:, password:)
      @raw = token.to_s
      @password = password.to_s
    end

    def call
      customer = Customer.kept.find_by(reset_password_token_digest: TokenDigest.digest(@raw))
      raise InvalidToken, "Invalid or expired reset link" unless valid?(customer)

      Customer.transaction do
        customer.update!(
          password: @password,
          reset_password_token_digest: nil,
          reset_password_sent_at: nil
        )
        # Revoke every active session — a password reset logs out all devices.
        customer.refresh_tokens.active.update_all(revoked_at: Time.current)
      end

      customer
    end

    private

    def valid?(customer)
      customer.present? &&
        customer.reset_password_sent_at.present? &&
        customer.reset_password_sent_at > RESET_TTL.ago
    end
  end
end
