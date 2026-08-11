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
      rescue_from Checkout::VerifyPayment::Error do |error|
        render_error(code: "payment_verification_failed", message: error.message, status: :unprocessable_content)
      end

      # POST /api/v1/checkout  { shipping_method_id, address: { full_name, phone, line1, line2, city, state, postal_code, country } }
      # Creates the order in `pending` status with a Razorpay order started
      # for its total — the response's `payment` block is what the frontend
      # needs to open the Razorpay Checkout widget.
      def create
        order = Checkout::PlaceOrder.new(
          customer: current_customer,
          cart: Cart.find_by(customer: current_customer),
          shipping_method_id: params[:shipping_method_id],
          address: address_params
        ).call

        render_success(OrderSerializer.new(order).as_json, status: :created)
      end

      # POST /api/v1/checkout/:order_id/verify_payment  { razorpay_payment_id, razorpay_signature }
      # Called by the frontend right after the Razorpay Checkout widget
      # reports success — verifies the signature server-side before treating
      # the order as paid.
      def verify_payment
        order = current_customer.orders.find(params[:order_id])
        Checkout::VerifyPayment.new(
          order: order,
          razorpay_payment_id: params[:razorpay_payment_id],
          razorpay_signature: params[:razorpay_signature]
        ).call

        render_success(OrderSerializer.new(order.reload).as_json)
      end

      private

      def address_params
        params.require(:address).permit(:full_name, :phone, :line1, :line2, :city, :state, :postal_code, :country)
      end
    end
  end
end
