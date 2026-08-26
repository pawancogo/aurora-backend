# frozen_string_literal: true

FactoryBot.define do
  factory :review do
    product
    customer
    rating { 5 }
    title { "Great buy" }
    body { "This product was exactly what I needed and arrived quickly." }
    status { :pending }
    verified_purchase { true }

    trait :published do
      status { :published }
      published_at { Time.current }
    end

    trait :hidden do
      status { :hidden }
    end

    trait :with_photo do
      after(:create) do |review|
        review.images.create!(url: "https://example.com/review.jpg", position: 0)
      end
    end
  end

  factory :review_image do
    review
    sequence(:url) { |n| "https://example.com/review-#{n}.jpg" }
  end

  factory :review_vote do
    review
    customer
  end
end
