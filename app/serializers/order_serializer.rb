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
      items: @order.order_items.map { |item| OrderItemSerializer.new(item).as_json },
      payment: @order.pending? && (payment = @order.payments.order(:id).last) ? payment_json(payment) : nil,
      carrier_name: @order.carrier_name,
      tracking_number: @order.tracking_number,
      events: @order.order_events.map { |event| { description: event.description, occurred_at: event.occurred_at } }
    }
  end

  private

  # Only exposes what the Razorpay Checkout widget needs to open — the Key
  # ID is a public identifier (safe client-side), never the Key Secret.
  def payment_json(payment)
    {
      razorpay_order_id: payment.razorpay_order_id,
      razorpay_key_id: ENV["RAZORPAY_KEY_ID"],
      razorpay_config_id: SiteSetting.get("razorpay.config_id").presence,
      amount_cents: payment.amount_cents,
      currency: payment.currency
    }
  end
end
