# frozen_string_literal: true

module Admin
  # Settings area — tabbed: Roles, Permissions, Team (admin users + role assignment).
  class SettingsController < BaseController
    before_action -> { require_permission!("users.manage") },
                  only: %i[show_admin new_admin create_admin update_admin_roles update_admin_status destroy_admin
                           revoke_admin_sessions revoke_admin_session]

    # GET /admin/settings
    def index
      redirect_to admin_settings_roles_path
    end

    # GET /admin/settings/permissions
    def permissions
      @permissions = Permission.search(params, scope: Permission.includes(:roles).order(:key)).records
    end

    # GET /admin/settings/team
    def team
      load_team
    end

    # GET /admin/settings/team/:id — admin user detail + login sessions
    def show_admin
      @admin = AdminUser.kept.includes(:roles).find(params[:id])
      @roles = Role.order(:name)
      @sessions = @admin.refresh_tokens.order(created_at: :desc).limit(50)
    end

    # GET /admin/settings/team/new — new admin form (own page, not inline)
    def new_admin
      @new_admin = AdminUser.new
      @roles = Role.order(:name)
    end

    # POST /admin/settings/team — create an admin user
    def create_admin
      admin = AdminUser.new(admin_params)
      admin.role_ids = submitted_role_ids

      if admin.save
        redirect_to admin_settings_team_path, notice: "Admin #{admin.email} created."
      else
        @new_admin = admin
        @roles = Role.order(:name)
        render :new_admin, status: :unprocessable_content
      end
    end

    # PATCH /admin/settings/team/:id/roles
    def update_admin_roles
      admin = AdminUser.kept.find(params[:id])
      return redirect_to admin_settings_team_path, alert: "You cannot change your own roles." if admin == current_admin_user

      admin.role_ids = submitted_role_ids
      redirect_to admin_settings_admin_path(admin), notice: "Roles updated for #{admin.email}."
    end

    # PATCH /admin/settings/team/:id/status
    def update_admin_status
      admin = AdminUser.kept.find(params[:id])
      return redirect_to admin_settings_team_path, alert: "You cannot change your own status." if admin == current_admin_user

      new_status = admin.status == "active" ? "inactive" : "active"
      admin.update!(status: new_status)
      redirect_to admin_settings_admin_path(admin), notice: "#{admin.email} marked #{new_status}."
    end

    # DELETE /admin/settings/team/:id
    def destroy_admin
      admin = AdminUser.kept.find(params[:id])
      return redirect_to admin_settings_team_path, alert: "You cannot remove your own account." if admin == current_admin_user

      admin.discard!
      redirect_to admin_settings_team_path, notice: "Admin #{admin.email} removed."
    end

    # DELETE /admin/settings/team/:id/sessions — revoke all active sessions
    def revoke_admin_sessions
      admin = AdminUser.kept.find(params[:id])
      count = admin.refresh_tokens.active.update_all(revoked_at: Time.current)
      redirect_to admin_settings_admin_path(admin), notice: "Revoked #{count} active session(s)."
    end

    # DELETE /admin/settings/team/:id/sessions/:token_id — revoke a single session
    def revoke_admin_session
      admin = AdminUser.kept.find(params[:id])
      admin.refresh_tokens.find(params[:token_id]).revoke!
      redirect_to admin_settings_admin_path(admin), notice: "Session revoked."
    end

    private

    def load_team
      result = AdminUser.search(params, scope: AdminUser.kept.includes(:roles).order(:email))
      @admin_facets = result.facets
      @admins = result.records
    end

    def admin_params
      params.require(:admin_user).permit(:email, :first_name, :last_name, :password)
    end

    def submitted_role_ids
      Array(params[:role_ids]).reject(&:blank?)
    end
  end
end
