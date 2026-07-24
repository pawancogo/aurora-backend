# frozen_string_literal: true

module Admin
  # Base controller for the server-rendered admin portal (ERB, session-authenticated).
  # Distinct from the stateless JWT customer/admin JSON API under /api/v1.
  class BaseController < ActionController::Base
    protect_from_forgery with: :exception
    layout "admin"

    helper_method :current_admin_user, :admin_signed_in?, :allowed_to?

    before_action :authenticate_admin!

    private

    # Permission check for the portal (mirrors AdminUser#can?; super admins get everything).
    def allowed_to?(permission_key)
      current_admin_user&.can?(permission_key) || false
    end

    def require_permission!(permission_key)
      return if allowed_to?(permission_key)

      redirect_back fallback_location: admin_root_path,
                    alert: "You don't have permission to do that."
    end

    def current_admin_user
      return @current_admin_user if defined?(@current_admin_user)

      @current_admin_user =
        session[:admin_user_id] && AdminUser.kept.find_by(id: session[:admin_user_id])
    end

    def admin_signed_in?
      current_admin_user.present? && current_admin_user.active_for_auth?
    end

    def authenticate_admin!
      return if admin_signed_in?

      redirect_to admin_login_path, alert: "Please sign in to continue."
    end
  end
end
