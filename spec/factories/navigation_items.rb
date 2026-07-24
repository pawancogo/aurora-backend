# frozen_string_literal: true

FactoryBot.define do
  factory :navigation_item do
    sequence(:label) { |n| "Item #{n}" }
    location { "header" }
    link_type { "internal" }
    visible { true }
    position { 0 }

    trait :hidden do
      visible { false }
    end
  end
end
