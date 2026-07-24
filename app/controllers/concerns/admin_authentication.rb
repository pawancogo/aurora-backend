# frozen_string_literal: true

# Resolves and requires the current admin user, plus permission-based authorization.
module AdminAuthentication
  extend ActiveSupport::Concern
  include BearerTokenDecoding

  class UnauthorizedError < StandardError; end
  class ForbiddenError < StandardError; end

  included do
    rescue_from AdminAuthentication::UnauthorizedError do |error|
      render_error(code: "unauthorized", message: error.message, status: :unauthorized)
    end
    rescue_from AdminAuthentication::ForbiddenError do |error|
      render_error(code: "forbidden", message: error.message, status: :forbidden)
    end
  end

  private

  def authenticate_admin!
    current_admin_user || raise(UnauthorizedError, "Authentication required")
  end

  def authorize_permission!(key)
    authenticate_admin!
    return if current_admin_user.can?(key)

    raise ForbiddenError, "Missing required permission: #{key}"
  end

  def current_admin_user
    return @current_admin_user if defined?(@current_admin_user)

    @current_admin_user = resolve_current_admin_user
  end

  def resolve_current_admin_user
    payload = decoded_token
    return nil unless payload && payload[:typ] == "AdminUser"

    admin = AdminUser.kept.find_by(id: payload[:sub])
    admin if admin&.active_for_auth?
  end
end
