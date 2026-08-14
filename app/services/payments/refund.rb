# frozen_string_literal: true

module Payments
  # Actually moves money back to the customer via Razorpay — the one and
  # only place that happens. Deliberately a separate, manual step from
  # cancellation (Order#perform_cancel! only flags the payment as
  # refund_pending): staff must click "Refund payment" themselves.
  class Refund
    class Error < StandardError; end

    def initialize(payment:)
      @payment = payment
    end

    def call
      raise Error, "This payment isn't awaiting a refund" unless @payment.refund_pending?

      refund = Razorpay::Refund.create(payment_id: @payment.razorpay_payment_id, amount: @payment.amount_cents)
      @payment.update!(status: :refunded, razorpay_refund_id: refund.id, refunded_at: Time.current)
      @payment
    rescue Razorpay::Error => e
      raise Error, "Razorpay refund failed: #{e.message}"
    end
  end
end
