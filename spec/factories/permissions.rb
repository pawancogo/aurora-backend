# frozen_string_literal: true

FactoryBot.define do
  factory :permission do
    sequence(:key) { |n| "resource#{n}.read" }
    sequence(:name) { |n| "Permission #{n}" }
  end
end
