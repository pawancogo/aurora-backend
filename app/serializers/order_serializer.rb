# frozen_string_literal: true

# Full order detail: totals, shipping snapshot, and every line item.
class OrderSerializer
  def initialize(order)
    @order = order
  end

  def as_json(*)
    {
      id: @order.id,
      order_number: @order.order_number,
      status: @order.status,
      cancellable: @order.cancellable?,
      subtotal: @order.subtotal,
      shipping: @order.shipping,
      total: @order.total,
      currency: @order.currency,
      shipping_method_name: @order.shipping_method_name,
      placed_at: @order.placed_at,
      shipping_address: @order.shipping_address && OrderAddressSerializer.new(@order.shipping_address).as_json,
      items: @order.order_items.map { |item| OrderItemSerializer.new(item).as_json }
    }
  end
end
