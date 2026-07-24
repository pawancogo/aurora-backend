# frozen_string_literal: true

FactoryBot.define do
  factory :category do
    sequence(:name) { |n| "Category #{n}" }
    visible { true }

    trait :hidden do
      visible { false }
    end
  end
end
