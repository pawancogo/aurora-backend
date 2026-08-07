# frozen_string_literal: true

FactoryBot.define do
  factory :wishlist_item do
    customer
    product
  end
end
