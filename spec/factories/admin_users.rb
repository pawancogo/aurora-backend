# frozen_string_literal: true

FactoryBot.define do
  factory :admin_user do
    sequence(:email) { |n| "admin#{n}@example.com" }
    password { "password1234" }
    first_name { "Test" }
    last_name { "Admin" }

    trait :super_admin do
      after(:create) do |admin|
        role = Role.find_or_create_by!(key: "super_admin") do |r|
          r.name = "Super Admin"
          r.system = true
        end
        admin.roles << role unless admin.roles.include?(role)
      end
    end
  end
end
