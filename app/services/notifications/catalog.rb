# frozen_string_literal: true

module Notifications
  # Event definitions. Adding a new notification is: add a key here, then
  # call Notify from the domain event. Adding a new *channel* (WhatsApp, …)
  # is: write Channels::X, register it, and add the symbol to an event's
  # `channels` list — Notify fans out without other changes.
  module Catalog
    CHANNELS = %i[in_app email sms push].freeze

    EVENTS = {
      "order.placed" => {
        title: "Order placed",
        body: "We've received order %{order_number} for %{total}. We'll email you again when payment is confirmed.",
        transactional: true,
        channels: %i[in_app email],
        url_template: "/account/orders/%{order_id}"
      },
      "order.confirmed" => {
        title: "Payment confirmed",
        body: "Payment for order %{order_number} (%{total}) is confirmed. We'll start packing it shortly.",
        transactional: true,
        channels: %i[in_app email],
        url_template: "/account/orders/%{order_id}"
      },
      "order.shipped" => {
        title: "Order shipped",
        body: "Order %{order_number} is on the way with %{carrier_name}. Tracking: %{tracking_number}.",
        transactional: true,
        channels: %i[in_app email],
        url_template: "/account/orders/%{order_id}"
      },
      "order.delivered" => {
        title: "Order delivered",
        body: "Order %{order_number} has been delivered. We hope you love it.",
        transactional: true,
        channels: %i[in_app email],
        url_template: "/account/orders/%{order_id}"
      },
      "order.cancelled" => {
        title: "Order cancelled",
        body: "Order %{order_number} has been cancelled. If you paid, a refund will be processed separately.",
        transactional: true,
        channels: %i[in_app email],
        url_template: "/account/orders/%{order_id}"
      },
      "order.payment_failed" => {
        title: "Payment didn't go through",
        body: "We couldn't confirm payment for order %{order_number}. You can retry checkout from your cart.",
        transactional: true,
        channels: %i[in_app email],
        url_template: "/account/orders/%{order_id}"
      },
      "order.refunded" => {
        title: "Refund sent",
        body: "A refund of %{refund_amount} for order %{order_number} is on its way to your original payment method.",
        transactional: true,
        channels: %i[in_app email],
        url_template: "/account/orders/%{order_id}"
      },
      "return.requested" => {
        title: "Return requested",
        body: "We've received return %{rma_number} for order %{order_number}. We'll review it shortly.",
        transactional: true,
        channels: %i[in_app email],
        url_template: "/account/returns/%{return_id}"
      },
      "return.approved" => {
        title: "Return approved",
        body: "Return %{rma_number} is approved. Please send the items back using the instructions in your account.",
        transactional: true,
        channels: %i[in_app email],
        url_template: "/account/returns/%{return_id}"
      },
      "return.rejected" => {
        title: "Return not approved",
        body: "Return %{rma_number} was not approved. Open the return in your account for details.",
        transactional: true,
        channels: %i[in_app email],
        url_template: "/account/returns/%{return_id}"
      },
      "return.completed" => {
        title: "Return completed",
        body: "Return %{rma_number} is complete. If a refund is due, it will be processed next.",
        transactional: true,
        channels: %i[in_app email],
        url_template: "/account/returns/%{return_id}"
      },
      "review.request" => {
        title: "How was your order?",
        body: "Order %{order_number} was delivered. A short review helps other shoppers — and us.",
        transactional: false,
        channels: %i[in_app email],
        url_template: "/account/reviews"
      }
    }.freeze

    module_function

    def fetch!(key)
      EVENTS.fetch(key.to_s) { raise ArgumentError, "Unknown notification event: #{key}" }
    end

    def keys
      EVENTS.keys
    end

    def interpolate(template, payload)
      payload = payload.stringify_keys
      template.to_s.gsub(/%\{(\w+)\}/) { payload[::Regexp.last_match(1)].to_s }
    end

    def transactional?(key)
      fetch!(key)[:transactional]
    end
  end
end
