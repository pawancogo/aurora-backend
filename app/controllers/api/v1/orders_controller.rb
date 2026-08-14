# frozen_string_literal: true

module Api
  module V1
    # The signed-in customer's own order history + detail.
    class OrdersController < BaseController
      include CustomerAuthentication

      before_action :authenticate_customer!

      # GET /api/v1/orders
      def index
        orders, meta = paginate(current_customer.orders.order(placed_at: :desc))
        render_success(orders.map { |order| OrderListSerializer.new(order).as_json }, meta: meta)
      end

      # GET /api/v1/orders/:id
      def show
        order = current_customer.orders.find(params[:id])
        render_success(OrderSerializer.new(order).as_json)
      end

      # POST /api/v1/orders/:id/cancel
      def cancel
        order = current_customer.orders.find(params[:id])
        unless order.cancel!
          return render_error(
            code: "order_not_cancellable",
            message: "This order can no longer be cancelled.",
            status: :unprocessable_content
          )
        end

        render_success(OrderSerializer.new(order).as_json)
      end
    end
  end
end
