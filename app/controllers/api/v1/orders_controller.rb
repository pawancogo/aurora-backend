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

      # PATCH /api/v1/orders/:id/shipping_address { address: { ... } }
      def update_shipping_address
        order = current_customer.orders.find(params[:id])
        unless order.cancellable?
          return render_error(
            code: "address_not_editable",
            message: "This order has already moved too far along to change its address.",
            status: :unprocessable_content
          )
        end

        order.update_shipping_address!(address_params)
        render_success(OrderSerializer.new(order).as_json)
      end

      private

      def address_params
        params.require(:address).permit(:full_name, :phone, :line1, :line2, :city, :state, :postal_code, :country)
      end
    end
  end
end
