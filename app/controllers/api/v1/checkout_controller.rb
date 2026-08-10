# frozen_string_literal: true

module Api
  module V1
    # Places an order from the signed-in customer's cart. Checkout requires an
    # account — there's no guest order flow (guests can browse/cart, but must
    # sign in to place an order; their guest cart already merges on login).
    class CheckoutController < BaseController
      include CustomerAuthentication

      before_action :authenticate_customer!

      rescue_from Checkout::PlaceOrder::Error do |error|
        render_error(code: "checkout_error", message: error.message, status: :unprocessable_content)
      end

      # POST /api/v1/checkout  { shipping_method_id, address: { full_name, phone, line1, line2, city, state, postal_code, country } }
      def create
        order = Checkout::PlaceOrder.new(
          customer: current_customer,
          cart: Cart.find_by(customer: current_customer),
          shipping_method_id: params[:shipping_method_id],
          address: address_params
        ).call

        render_success(OrderSerializer.new(order).as_json, status: :created)
      end

      private

      def address_params
        params.require(:address).permit(:full_name, :phone, :line1, :line2, :city, :state, :postal_code, :country)
      end
    end
  end
end
