# frozen_string_literal: true

module Auth
  # Verifies admin credentials and records the login timestamp.
  class AuthenticateAdmin
    class AuthenticationError < StandardError; end

    def initialize(email:, password:)
      @email = email.to_s.strip.downcase
      @password = password.to_s
    end

    def call
      admin = AdminUser.kept.find_by(email: @email)

      raise AuthenticationError, "Invalid email or password" unless admin&.authenticate(@password)
      raise AuthenticationError, "Your account is inactive" unless admin.active_for_auth?

      admin.update_column(:last_login_at, Time.current)
      admin
    end
  end
end
