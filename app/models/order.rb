# frozen_string_literal: true

# A placed order — created by Checkout::PlaceOrder from a customer's cart.
# Money/shipping fields are snapshotted at placement; later changes to the
# shipping method or catalog never alter a past order.
class Order < ApplicationRecord
  include SearchManager

  search_manager on: %i[order_number], aggs_on: %i[status], range_on: :total_cents

  has_paper_trail

  belongs_to :customer
  belongs_to :shipping_method, optional: true
  has_many :order_items, dependent: :destroy
  has_many :order_addresses, dependent: :destroy
  has_many :payments, dependent: :destroy
  has_many :order_events, -> { order(:occurred_at) }, dependent: :destroy

  # `pending` = placed, awaiting payment confirmation (inventory reserved,
  # not yet decremented). `payment_failed` = the payment attempt failed or
  # was abandoned; the shopper can retry from the checkout page.
  enum :status, {
    pending: 0,
    confirmed: 1,
    ready_to_ship: 2,
    shipped: 3,
    delivered: 4,
    cancelled: 5,
    refunded: 6,
    returned: 7,
    payment_failed: 8,
    accepted: 9
  }

  # The order in which a fulfilled order moves forward; drives the admin
  # "advance" action (always one step, never a free-form status picker).
  FULFILLMENT_SEQUENCE = %w[confirmed accepted ready_to_ship shipped delivered].freeze

  def next_status
    idx = FULFILLMENT_SEQUENCE.index(status)
    idx && FULFILLMENT_SEQUENCE[idx + 1]
  end

  before_validation :generate_order_number, on: :create

  validates :order_number, presence: true, uniqueness: true
  validates :subtotal_cents, :shipping_cents, :total_cents, numericality: { greater_than_or_equal_to: 0 }

  CANCELLABLE_STATES = %w[pending confirmed].freeze

  # Staff get more leeway than shoppers: they can still reject/cancel an
  # order they've already accepted for fulfillment, right up until it
  # physically ships. Past that point it's shipped/delivered and needs a
  # proper return, not a cancellation.
  ADMIN_CANCELLABLE_STATES = (CANCELLABLE_STATES + %w[accepted ready_to_ship]).freeze

  def cancellable?
    status.in?(CANCELLABLE_STATES)
  end

  def admin_cancellable?
    status.in?(ADMIN_CANCELLABLE_STATES)
  end

  def cancel!
    cancellable? ? perform_cancel! : false
  end

  def admin_cancel!
    admin_cancellable? ? perform_cancel! : false
  end

  # The payment (if any) sitting in refund_pending on this order — surfaces
  # a manual "Refund payment" action in the admin. Refunds are never
  # automatic: cancelling only flags the payment as needing one.
  def refund_payment
    payments.find(&:refund_pending?)
  end

  def refund_pending?
    refund_payment.present?
  end

  def shipping_address
    order_addresses.shipping.first
  end

  # Reuses the same eligibility as cancellation — if the order can still be
  # cancelled outright, it's also safe to just fix the address on it. No
  # separate "editable states" config; one rule covers both.
  def update_shipping_address!(attrs)
    shipping_address.update!(attrs)
  end

  def subtotal
    subtotal_cents / 100.0
  end

  def shipping
    shipping_cents / 100.0
  end

  def total
    total_cents / 100.0
  end

  private

  def perform_cancel!
    transaction do
      order_items.includes(product_variant: :inventory_item).each do |item|
        inventory_item = item.product_variant&.inventory_item
        Inventory::Release.new(inventory_item: inventory_item, quantity: item.quantity).call if inventory_item
      end
      # Money already taken needs a refund, but never automatically — this
      # only flags it; an admin has to click "Refund payment" to actually
      # move money back (Payments::Refund).
      payments.captured.each { |payment| payment.update!(status: :refund_pending) }
      update!(status: :cancelled, cancelled_at: Time.current)
    end
    true
  end

  def generate_order_number
    loop do
      candidate = "ORD-#{SecureRandom.alphanumeric(10).upcase}"
      break self.order_number = candidate unless Order.exists?(order_number: candidate)
    end
  end
end
