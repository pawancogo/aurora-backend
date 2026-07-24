# frozen_string_literal: true

module Auth
  # Re-issues an email-verification token for an unconfirmed customer.
  # Enumeration-safe: returns nil silently when there is nothing to send.
  class ResendVerification
    def initialize(email:)
      @email = email.to_s.strip.downcase
    end

    def call
      customer = Customer.kept.find_by(email: @email)
      return nil unless customer && !customer.confirmed?

      raw = SecureRandom.urlsafe_base64(32)
      customer.update!(
        confirmation_token_digest: TokenDigest.digest(raw),
        confirmation_sent_at: Time.current
      )
      CustomerMailer.verification_email(customer.id, raw).deliver_later
      raw
    end
  end
end
