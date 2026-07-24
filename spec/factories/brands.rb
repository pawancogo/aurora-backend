# frozen_string_literal: true

FactoryBot.define do
  factory :brand do
    sequence(:name) { |n| "Brand #{n}" }
  end
end
