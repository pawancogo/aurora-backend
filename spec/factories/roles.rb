# frozen_string_literal: true

FactoryBot.define do
  factory :role do
    sequence(:key) { |n| "role_#{n}" }
    sequence(:name) { |n| "Role #{n}" }
  end
end
