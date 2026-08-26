# frozen_string_literal: true

FactoryBot.define do
  factory :return_request do
    order { association :order, status: :delivered }
    customer { order.customer }
    reason { "Size doesn't fit" }
    resolution { :refund }

    after(:create) do |request|
      next if request.return_items.any?

      item = request.order.order_items.first || create(:order_item, order: request.order)
      create(:return_item, return_request: request, order_item: item, quantity: item.quantity)
    end
  end

  factory :return_item do
    return_request
    order_item { return_request.order.order_items.first || create(:order_item, order: return_request.order) }
    quantity { order_item.quantity }
  end
end
