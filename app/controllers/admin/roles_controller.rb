# frozen_string_literal: true

module Admin
  # Role management (the "Roles" settings tab). Viewing is open to any admin;
  # create/edit/delete + permission assignment require `roles.manage` (Super Admin).
  class RolesController < BaseController
    before_action -> { require_permission!("roles.manage") }, only: %i[new create edit update destroy]
    before_action :set_role, only: %i[edit update destroy]

    def index
      @roles = Role.search(params, scope: Role.includes(:permissions).order(:name)).records
    end

    def new
      @role = Role.new
      @permissions = all_permissions
    end

    def create
      @role = Role.new(create_params)
      @role.permission_ids = submitted_permission_ids

      if @role.save
        redirect_to admin_settings_roles_path, notice: "Role “#{@role.name}” created."
      else
        @permissions = all_permissions
        render :new, status: :unprocessable_content
      end
    end

    def edit
      @permissions = all_permissions
    end

    def update
      @role.assign_attributes(update_params)
      @role.permission_ids = submitted_permission_ids

      if @role.save
        redirect_to admin_settings_roles_path, notice: "Role “#{@role.name}” updated."
      else
        @permissions = all_permissions
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      if @role.system?
        redirect_to admin_settings_roles_path, alert: "System roles cannot be deleted."
      elsif @role.admin_users.exists?
        redirect_to admin_settings_roles_path, alert: "Unassign this role from all admins before deleting it."
      else
        @role.destroy
        redirect_to admin_settings_roles_path, notice: "Role deleted."
      end
    end

    private

    def set_role
      @role = Role.find(params[:id])
    end

    def all_permissions
      Permission.order(:key)
    end

    # Key is the programmatic identifier — settable on create, immutable on edit.
    def create_params
      params.require(:role).permit(:name, :key, :description)
    end

    def update_params
      params.require(:role).permit(:name, :description)
    end

    def submitted_permission_ids
      Array(params.dig(:role, :permission_ids)).reject(&:blank?)
    end
  end
end
