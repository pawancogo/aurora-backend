# frozen_string_literal: true

class RoleSerializer
  def initialize(role)
    @role = role
  end

  def as_json(*)
    {
      id: @role.id,
      key: @role.key,
      name: @role.name,
      description: @role.description,
      system: @role.system,
      permissions: @role.permissions.map(&:key)
    }
  end
end
