# frozen_string_literal: true

module Admin
  # Permissions are code-enforced capabilities: their KEY is a fixed contract with
  # the app, so keys can't be created or deleted here. What IS editable is the
  # human-readable name/description and which roles are granted the permission.
  class PermissionsController < BaseController
    before_action -> { require_permission!("permissions.manage") }, only: %i[edit update]
    before_action :set_permission, only: %i[edit update]
    before_action :load_roles, only: %i[edit update]

    def edit; end

    def update
      @permission.assign_attributes(permission_params)
      if @permission.save
        sync_role_assignments
        redirect_to admin_settings_permissions_path, notice: "Permission “#{@permission.key}” updated."
      else
        render :edit, status: :unprocessable_content
      end
    end

    private

    def set_permission
      @permission = Permission.find(params[:id])
    end

    # Super Admin implicitly holds every permission, so it's never listed for assignment.
    def load_roles
      @roles = Role.where.not(key: "super_admin").order(:name)
    end

    def permission_params
      params.require(:permission).permit(:name, :description)
    end

    def sync_role_assignments
      return unless params.key?(:role_ids)

      ids = Array(params[:role_ids]).reject(&:blank?)
      # Replace only the assignable (non-super_admin) roles; never touch Super Admin's
      # implicit grant, which is managed by the seeds / #can? bypass.
      keep = @permission.roles.where(key: "super_admin").to_a
      keep += Role.where(id: ids).where.not(key: "super_admin").to_a
      @permission.roles = keep
    end
  end
end
