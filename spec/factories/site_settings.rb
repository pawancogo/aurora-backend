# frozen_string_literal: true

FactoryBot.define do
  factory :site_setting do
    sequence(:key) { |n| "setting.key_#{n}" }
    value { "value" }
    value_type { "string" }
    category { "general" }
    public_read { false }
  end
end
