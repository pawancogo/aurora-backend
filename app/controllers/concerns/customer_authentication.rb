# frozen_string_literal: true

# Resolves and requires the current customer from a Bearer access token.
module CustomerAuthentication
  extend ActiveSupport::Concern
  include BearerTokenDecoding

  class UnauthorizedError < StandardError; end

  included do
    rescue_from CustomerAuthentication::UnauthorizedError do |error|
      render_error(code: "unauthorized", message: error.message, status: :unauthorized)
    end
  end

  private

  def authenticate_customer!
    current_customer || raise(UnauthorizedError, "Authentication required")
  end

  def current_customer
    return @current_customer if defined?(@current_customer)

    @current_customer = resolve_current_customer
  end

  def resolve_current_customer
    payload = decoded_token
    return nil unless payload && payload[:typ] == "Customer"

    customer = Customer.kept.find_by(id: payload[:sub])
    customer if customer&.active_for_auth?
  end
end
