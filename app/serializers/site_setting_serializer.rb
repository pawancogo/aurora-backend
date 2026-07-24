# frozen_string_literal: true

class SiteSettingSerializer
  def initialize(setting)
    @setting = setting
  end

  def as_json(*)
    {
      id: @setting.id,
      key: @setting.key,
      value: @setting.value,
      value_type: @setting.value_type,
      category: @setting.category,
      description: @setting.description,
      public_read: @setting.public_read
    }
  end
end
