# frozen_string_literal: true

module Api
  module V1
    # Receives Razorpay webhook events — a safety net for when the frontend's
    # post-checkout verify_payment call never fires (e.g. the browser closes
    # mid-payment). No customer/admin auth; trust is established entirely via
    # the HMAC signature Razorpay sends in X-Razorpay-Signature.
    class WebhooksController < BaseController
      CAPTURE_EVENTS = %w[payment.captured order.paid].freeze
      FAIL_EVENTS = %w[payment.failed].freeze

      # POST /api/v1/webhooks/razorpay
      def razorpay
        secret = ENV["RAZORPAY_WEBHOOK_SECRET"]
        signature = request.headers["X-Razorpay-Signature"]
        return head(:bad_request) if secret.blank? || signature.blank?

        body = request.raw_post
        Razorpay::Utility.verify_webhook_signature(body, signature, secret)

        process_event(JSON.parse(body))
        head :ok
      rescue SecurityError, JSON::ParserError
        head :bad_request
      end

      private

      def process_event(payload)
        event = payload["event"]
        return unless CAPTURE_EVENTS.include?(event) || FAIL_EVENTS.include?(event)

        payment = Payment.find_by(razorpay_order_id: order_id_from(payload))
        return if payment.nil?

        outcome = CAPTURE_EVENTS.include?(event) ? :captured : :failed
        Checkout::ApplyPaymentOutcome.new(
          payment: payment, outcome: outcome, razorpay_payment_id: payment_id_from(payload)
        ).call
      end

      def order_id_from(payload)
        payload.dig("payload", "payment", "entity", "order_id") || payload.dig("payload", "order", "entity", "id")
      end

      def payment_id_from(payload)
        payload.dig("payload", "payment", "entity", "id")
      end
    end
  end
end
