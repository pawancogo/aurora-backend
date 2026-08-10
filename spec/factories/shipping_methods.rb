# frozen_string_literal: true

FactoryBot.define do
  factory :shipping_method do
    sequence(:name) { |n| "Shipping #{n}" }
    price_cents { 0 }
    active { true }
  end
end
