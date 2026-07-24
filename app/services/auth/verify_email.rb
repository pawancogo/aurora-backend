# frozen_string_literal: true

module Auth
  # Confirms a customer's email given a raw verification token.
  class VerifyEmail
    class InvalidToken < StandardError; end

    def initialize(raw_token)
      @raw = raw_token.to_s
    end

    def call
      customer = Customer.kept.find_by(confirmation_token_digest: TokenDigest.digest(@raw))
      raise InvalidToken, "Invalid or expired verification link" unless valid?(customer)

      return customer if customer.confirmed?

      customer.update!(
        confirmed_at: Time.current,
        confirmation_token_digest: nil,
        confirmation_sent_at: nil
      )
      customer
    end

    private

    def valid?(customer)
      customer.present? &&
        customer.confirmation_token_digest.present? &&
        customer.confirmation_sent_at.present? &&
        customer.confirmation_sent_at > RegisterCustomer::CONFIRMATION_TTL.ago
    end
  end
end
