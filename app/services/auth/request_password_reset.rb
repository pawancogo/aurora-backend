# frozen_string_literal: true

module Auth
  # Issues a password-reset token. Always succeeds silently to avoid leaking which
  # emails are registered (enumeration-safe).
  class RequestPasswordReset
    def initialize(email:)
      @email = email.to_s.strip.downcase
    end

    # Returns the raw token when an account exists (used by tests), otherwise nil.
    def call
      customer = Customer.kept.find_by(email: @email)
      return nil unless customer

      raw = SecureRandom.urlsafe_base64(32)
      customer.update!(
        reset_password_token_digest: TokenDigest.digest(raw),
        reset_password_sent_at: Time.current
      )
      CustomerMailer.password_reset_email(customer.id, raw).deliver_later
      raw
    end
  end
end
