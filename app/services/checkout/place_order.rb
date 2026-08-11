# frozen_string_literal: true

module Checkout
  # Orchestrates cart -> order: re-validates every line (price/stock may have
  # moved since it was added to the cart), snapshots items + shipping address,
  # reserves inventory (not decremented yet — that happens once payment is
  # confirmed, in Checkout::VerifyPayment), and starts a Razorpay order for
  # the total. The local Order stays `pending` until the payment is verified.
  class PlaceOrder
    class Error < StandardError; end

    ADDRESS_FIELDS = %i[full_name phone line1 line2 city state postal_code country].freeze

    def initialize(customer:, cart:, shipping_method_id:, address:)
      @customer = customer
      @cart = cart
      @shipping_method_id = shipping_method_id
      @address = address
    end

    def call
      raise Error, "Your cart is empty" if @cart.nil? || @cart.cart_items.none?
      raise Error, "Payments are not configured yet" if Razorpay.auth.blank?

      items = @cart.cart_items.includes(product_variant: [ :product, :inventory_item, { variant_option_values: { attribute_value: :product_attribute } } ]).to_a
      items.each { |item| validate_purchasable!(item) }

      shipping_method = resolve_shipping_method!
      subtotal_cents = items.sum(&:line_total_cents)
      shipping_cents = shipping_method&.price_cents || 0

      order = nil
      Order.transaction do
        order = Order.create!(
          customer: @customer,
          shipping_method: shipping_method,
          shipping_method_name: shipping_method&.name || "Standard",
          status: :pending,
          subtotal_cents: subtotal_cents,
          shipping_cents: shipping_cents,
          total_cents: subtotal_cents + shipping_cents,
          currency: "INR",
          placed_at: Time.current
        )

        items.each { |item| create_order_item!(order, item) }
        order.order_addresses.create!(address_attributes.merge(address_type: :shipping))
        items.each { |item| reserve_inventory!(item) }
        create_payment!(order)

        @cart.cart_items.destroy_all
      end

      order
    end

    private

    def validate_purchasable!(item)
      variant = item.product_variant
      raise Error, "#{variant&.sku || 'An item'} is no longer available" unless variant&.active?
      raise Error, "#{variant.product&.name} is no longer available" unless variant.product&.kept? && variant.product.active?
      raise Error, "#{variant.product.name} is out of stock" unless variant.in_stock?
    end

    def resolve_shipping_method!
      return nil if @shipping_method_id.blank?

      ShippingMethod.active.find(@shipping_method_id)
    rescue ActiveRecord::RecordNotFound
      raise Error, "Select a valid shipping method"
    end

    def create_order_item!(order, item)
      variant = item.product_variant
      order.order_items.create!(
        product_variant: variant,
        product_name: variant.product.name,
        variant_sku: variant.sku,
        options_snapshot: variant.attribute_values.map { |v| { attribute: v.product_attribute&.name, value: v.value } },
        unit_price_cents: item.unit_price_cents,
        quantity: item.quantity,
        line_total_cents: item.line_total_cents
      )
    end

    # Holds stock in `reserved` (on-hand untouched) rather than decrementing
    # outright — the sale only becomes real once the payment is verified.
    # Unlike the old direct decrement, this does NOT silently cap at what's
    # on hand: if there isn't enough to reserve, the customer needs to know
    # before they're sent to pay, not after.
    def reserve_inventory!(item)
      inventory_item = item.product_variant.inventory_item
      return unless inventory_item

      Inventory::Reserve.new(inventory_item: inventory_item, quantity: item.quantity).call
    rescue Inventory::Error => e
      raise Error, "#{item.product_variant.product.name}: #{e.message}"
    end

    def create_payment!(order)
      razorpay_order = Razorpay::Order.create(
        amount: order.total_cents, currency: order.currency, receipt: order.order_number
      )
      order.payments.create!(
        razorpay_order_id: razorpay_order.id, amount_cents: order.total_cents, currency: order.currency
      )
    rescue Razorpay::Error => e
      raise Error, "Could not start payment: #{e.message}"
    rescue StandardError
      raise Error, "The payment gateway is unavailable right now — please try again shortly."
    end

    def address_attributes
      @address.to_h.symbolize_keys.slice(*ADDRESS_FIELDS)
    end
  end
end
