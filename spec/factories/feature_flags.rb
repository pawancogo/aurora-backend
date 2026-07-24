# frozen_string_literal: true

FactoryBot.define do
  factory :feature_flag do
    sequence(:key) { |n| "flag_#{n}" }
    sequence(:name) { |n| "Flag #{n}" }
    enabled { false }
  end
end
