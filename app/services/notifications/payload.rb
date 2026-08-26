# frozen_string_literal: true

module Notifications
  module Payload
    module_function

    def for_order(order)
      {
        "order_id" => order.id,
        "order_number" => order.order_number,
        "total" => money(order.total_cents, order.currency),
        "refund_amount" => money(order.total_cents, order.currency),
        "carrier_name" => order.carrier_name.presence || "our courier",
        "tracking_number" => order.tracking_number.presence || "available soon",
        "customer_name" => order.customer.full_name.presence || "there"
      }
    end

    def for_return(request)
      for_order(request.order).merge(
        "return_id" => request.id,
        "rma_number" => request.rma_number,
        "reason" => request.reason,
        "resolution" => request.resolution
      )
    end

    def money(cents, currency = "INR")
      amount = format("%.2f", cents.to_i / 100.0)
      currency.to_s.upcase == "INR" ? "₹#{amount}" : "#{currency} #{amount}"
    end
  end
end
