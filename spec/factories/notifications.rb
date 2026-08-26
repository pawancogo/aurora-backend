# frozen_string_literal: true

FactoryBot.define do
  factory :notification do
    customer
    association :notifiable, factory: :order
    event_key { "order.placed" }
    title { "Order placed" }
    body { "We've received your order." }
    url { "/account/orders/1" }
    payload { { "order_number" => "ORD-TEST" } }

    trait :read do
      read_at { Time.current }
    end
  end

  factory :notification_delivery do
    notification
    channel { "email" }
    status { :pending }
  end

  factory :notification_preference do
    customer
    event_key { "review.request" }
    channel { "email" }
    enabled { true }
  end
end
