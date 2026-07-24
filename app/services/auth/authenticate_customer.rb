# frozen_string_literal: true

module Auth
  # Verifies customer credentials. Raises enumeration-safe errors.
  class AuthenticateCustomer
    class AuthenticationError < StandardError; end
    class UnconfirmedError < StandardError; end

    def initialize(email:, password:)
      @email = email.to_s.strip.downcase
      @password = password.to_s
    end

    def call
      customer = Customer.kept.find_by(email: @email)

      raise AuthenticationError, "Invalid email or password" unless customer&.authenticate(@password)
      raise AuthenticationError, "Your account is inactive" unless customer.active_for_auth?
      raise UnconfirmedError, "Please verify your email before signing in" unless customer.confirmed?

      customer
    end
  end
end
