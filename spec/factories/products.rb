# frozen_string_literal: true

FactoryBot.define do
  factory :product do
    sequence(:name) { |n| "Product #{n}" }
    sequence(:sku) { |n| "SKU-#{n}" }
    status { :active }
    published_at { Time.current }
    price_cents { 1000 }
    mrp_cents { 2000 }
    currency { "INR" }

    trait :draft do
      status { :draft }
    end

    trait :scheduled do
      published_at { 1.day.from_now }
    end

    trait :with_image do
      after(:create) do |product|
        product.product_images.create!(source_url: "https://example.com/image.jpg", primary: true)
      end
    end
  end

  factory :product_image do
    product
    sequence(:source_url) { |n| "https://example.com/#{n}.jpg" }
  end
end
