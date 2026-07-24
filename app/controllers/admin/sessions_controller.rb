# frozen_string_literal: true

module Admin
  class SessionsController < BaseController
    layout "admin_auth"
    skip_before_action :authenticate_admin!, only: %i[new create]

    # GET /admin/login
    def new
      redirect_to admin_root_path if admin_signed_in?
    end

    # POST /admin/login
    def create
      admin = AdminUser.kept.find_by(email: params[:email].to_s.strip.downcase)

      if admin&.authenticate(params[:password]) && admin.active_for_auth?
        reset_session
        session[:admin_user_id] = admin.id
        admin.update_column(:last_login_at, Time.current)
        redirect_to admin_root_path, notice: "Welcome back, #{admin.full_name || admin.email}."
      else
        flash.now[:alert] = "Invalid email or password."
        render :new, status: :unprocessable_content
      end
    end

    # DELETE /admin/logout
    def destroy
      reset_session
      redirect_to admin_login_path, notice: "You have been signed out."
    end
  end
end
