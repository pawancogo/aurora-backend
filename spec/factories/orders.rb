# frozen_string_literal: true

FactoryBot.define do
  factory :order do
    customer
    status { :confirmed }
    shipping_method_name { "Standard" }
    subtotal_cents { 1000 }
    shipping_cents { 0 }
    total_cents { 1000 }
    placed_at { Time.current }
  end

  factory :order_item do
    order
    product_variant
    product_name { "Test Product" }
    variant_sku { "SKU-TEST" }
    options_snapshot { [] }
    unit_price_cents { 500 }
    quantity { 2 }
    line_total_cents { 1000 }
  end

  factory :order_address do
    order
    address_type { :shipping }
    full_name { "Jane Doe" }
    phone { "9999999999" }
    line1 { "123 Main St" }
    city { "Mumbai" }
    state { "Maharashtra" }
    postal_code { "400001" }
    country { "IN" }
  end

  factory :payment do
    order
    sequence(:razorpay_order_id) { |n| "order_TEST#{n}" }
    amount_cents { 1000 }
    status { :created }
  end
end
