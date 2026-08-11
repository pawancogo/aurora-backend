# frozen_string_literal: true

module Checkout
  # Applies the result of a payment attempt to its Payment + Order — shared
  # by the synchronous post-checkout verification call (Checkout::VerifyPayment)
  # and the Razorpay webhook (a safety net for when the browser closes before
  # that call fires). Idempotent: whichever path reaches an already-resolved
  # payment second is a no-op, so it's safe for both to run on the same order.
  class ApplyPaymentOutcome
    def initialize(payment:, outcome:, razorpay_payment_id: nil, razorpay_signature: nil)
      @payment = payment
      @outcome = outcome.to_sym
      @razorpay_payment_id = razorpay_payment_id
      @razorpay_signature = razorpay_signature
    end

    def call
      return @payment.order if @payment.captured? || @payment.failed?

      @outcome == :captured ? capture! : fail!
      @payment.order
    end

    private

    def capture!
      order = @payment.order
      Order.transaction do
        @payment.update!(status: :captured, razorpay_payment_id: @razorpay_payment_id, razorpay_signature: @razorpay_signature)
        order.order_items.includes(product_variant: :inventory_item).each { |item| fulfil!(item) }
        order.update!(status: :confirmed)
      end
    end

    def fail!
      order = @payment.order
      Order.transaction do
        @payment.update!(status: :failed, razorpay_payment_id: @razorpay_payment_id, razorpay_signature: @razorpay_signature)
        order.order_items.includes(product_variant: :inventory_item).each { |item| release!(item) }
        order.update!(status: :payment_failed)
      end
    end

    # Converts the reservation into a real sale: releases the held quantity
    # and decrements on-hand for what's truly available (mirrors the cap
    # Checkout::PlaceOrder used to apply directly, before payment existed).
    def fulfil!(item)
      inventory_item = item.product_variant&.inventory_item
      return unless inventory_item

      decrement = [ item.quantity, inventory_item.on_hand ].min
      Inventory::Release.new(inventory_item: inventory_item, quantity: item.quantity).call
      Inventory::AdjustStock.new(inventory_item: inventory_item, quantity: -decrement, reason: "sale").call if decrement.positive?
    end

    def release!(item)
      inventory_item = item.product_variant&.inventory_item
      return unless inventory_item

      Inventory::Release.new(inventory_item: inventory_item, quantity: item.quantity).call
    end
  end
end
