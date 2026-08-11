# frozen_string_literal: true

module Checkout
  # Called right after the Razorpay Checkout widget succeeds on the
  # frontend. Verifies the HMAC signature Razorpay returned alongside the
  # payment/order ids — this is the primary confirmation path; the webhook
  # (Api::V1::WebhooksController) exists only as a safety net if this call
  # never fires (e.g. the browser closes mid-payment).
  class VerifyPayment
    class Error < StandardError; end

    def initialize(order:, razorpay_payment_id:, razorpay_signature:)
      @order = order
      @razorpay_payment_id = razorpay_payment_id
      @razorpay_signature = razorpay_signature
    end

    def call
      payment = @order.payments.order(:id).last
      raise Error, "No payment attempt found for this order" if payment.nil?
      raise Error, "This order has already been processed" unless @order.pending? || @order.payment_failed?

      # A retry reuses the same Razorpay order (Razorpay itself allows more
      # than one payment attempt against an order until one succeeds), so a
      # previously-failed Payment row is reopened rather than duplicated.
      payment.update!(status: :created) if payment.failed?

      outcome = signature_valid?(payment) ? :captured : :failed
      Checkout::ApplyPaymentOutcome.new(
        payment: payment, outcome: outcome,
        razorpay_payment_id: @razorpay_payment_id, razorpay_signature: @razorpay_signature
      ).call
    end

    private

    def signature_valid?(payment)
      Razorpay::Utility.verify_payment_signature(
        razorpay_order_id: payment.razorpay_order_id,
        razorpay_payment_id: @razorpay_payment_id,
        razorpay_signature: @razorpay_signature
      )
    rescue SecurityError, Razorpay::Error
      false
    end
  end
end
