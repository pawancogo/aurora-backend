# frozen_string_literal: true

class PermissionSerializer
  def initialize(permission)
    @permission = permission
  end

  def as_json(*)
    {
      id: @permission.id,
      key: @permission.key,
      name: @permission.name,
      description: @permission.description
    }
  end
end
