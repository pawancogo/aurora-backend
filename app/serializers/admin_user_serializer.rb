# frozen_string_literal: true

class AdminUserSerializer
  def initialize(admin_user)
    @admin_user = admin_user
  end

  def as_json(*)
    {
      id: @admin_user.id,
      email: @admin_user.email,
      first_name: @admin_user.first_name,
      last_name: @admin_user.last_name,
      full_name: @admin_user.full_name,
      status: @admin_user.status,
      roles: @admin_user.roles.map(&:key),
      permissions: @admin_user.permission_keys,
      created_at: @admin_user.created_at
    }
  end
end
