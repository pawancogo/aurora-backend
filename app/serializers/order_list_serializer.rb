# frozen_string_literal: true

# Compact order representation for order history listings.
class OrderListSerializer
  def initialize(order)
    @order = order
  end

  def as_json(*)
    {
      id: @order.id,
      order_number: @order.order_number,
      status: @order.status,
      total: @order.total,
      currency: @order.currency,
      item_count: @order.order_items.sum(:quantity),
      placed_at: @order.placed_at
    }
  end
end
