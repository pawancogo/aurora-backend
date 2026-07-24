# frozen_string_literal: true

FactoryBot.define do
  factory :customer do
    sequence(:email) { |n| "customer#{n}@example.com" }
    password { "password123" }
    first_name { "Test" }
    last_name { "Customer" }
    confirmed_at { Time.current }

    trait :unconfirmed do
      confirmed_at { nil }
    end

    trait :inactive do
      status { "inactive" }
    end
  end
end
