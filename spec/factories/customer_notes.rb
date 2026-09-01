# frozen_string_literal: true

FactoryBot.define do
  factory :customer_note do
    customer
    admin_user
    body { "Called the shopper about a delayed shipment." }
  end
end
