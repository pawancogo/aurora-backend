# frozen_string_literal: true

FactoryBot.define do
  factory :sprint do
    sequence(:number)
    title { "Cart & Wishlist" }
    goal { "Shopping cart and wishlist functionality." }
    status { :planned }
  end

  factory :sprint_feature do
    sprint
    area { :backend }
    title { "Cart merge on login" }
    description { "<p>Items in a shopper's cart before signing in are kept after signing in.</p>" }
    technical_description { "<p>Folds the guest cart into the customer's cart.</p>" }
    position { 0 }
  end
end
