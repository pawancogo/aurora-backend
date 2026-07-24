# frozen_string_literal: true

class FeatureFlagSerializer
  def initialize(flag)
    @flag = flag
  end

  def as_json(*)
    {
      id: @flag.id,
      key: @flag.key,
      name: @flag.name,
      description: @flag.description,
      enabled: @flag.enabled
    }
  end
end
