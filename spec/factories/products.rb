# frozen_string_literal: true

FactoryBot.define do
  factory :product do
    sequence(:name) { |n| "Product #{n}" }
    sequence(:sku) { |n| "SKU-#{n}" }
    status { :active }
    published_at { Time.current }
    currency { "INR" }

    transient do
      price_cents { 1000 }
      mrp_cents { 2000 }
    end

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

    # price_cents/mrp_cents are a cache synced from the master variant. For an
    # unsaved (build) product there's nothing to sync from, so mirror the
    # transient value onto the record itself; a saved product pushes it onto
    # the master variant instead, which syncs the cache back for real. Reads
    # the transient's original value (not product.price_cents) because the
    # master variant's own creation already zeroed the in-memory attribute.
    after(:build) do |product, evaluator|
      product.price_cents = evaluator.price_cents
      product.mrp_cents = evaluator.mrp_cents
    end

    after(:create) do |product, evaluator|
      product.master_variant.update!(price_cents: evaluator.price_cents, mrp_cents: evaluator.mrp_cents)
      product.reload
    end
  end

  factory :product_image do
    product
    sequence(:source_url) { |n| "https://example.com/#{n}.jpg" }
  end
end
