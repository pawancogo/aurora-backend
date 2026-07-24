# frozen_string_literal: true

module Auth
  # Creates a customer and dispatches an email-verification token.
  class RegisterCustomer
    CONFIRMATION_TTL = 2.days

    Result = Struct.new(:customer, :confirmation_token, keyword_init: true)

    def initialize(params)
      @params = params
    end

    def call
      customer = Customer.new(@params)
      raw = SecureRandom.urlsafe_base64(32)

      Customer.transaction do
        customer.confirmation_token_digest = TokenDigest.digest(raw)
        customer.confirmation_sent_at = Time.current
        customer.save!
      end

      CustomerMailer.verification_email(customer.id, raw).deliver_later

      Result.new(customer: customer, confirmation_token: raw)
    end
  end
end
