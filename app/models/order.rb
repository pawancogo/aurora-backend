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
  has_one :shipment, dependent: :destroy
  has_many :return_requests, dependent: :destroy

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

  before_validation :generate_order_number, on: :create

  validates :order_number, presence: true, uniqueness: true
  validates :subtotal_cents, :shipping_cents, :total_cents, numericality: { greater_than_or_equal_to: 0 }

  def next_status
    idx = FULFILLMENT_SEQUENCE.index(status)
    idx && FULFILLMENT_SEQUENCE[idx + 1]
  end

  # Staff can attach carrier/tracking/packing notes once the order is in
  # the fulfillment sequence, or afterwards if a shipment record already
  # exists (e.g. a cancelled order that had been accepted).
  def can_manage_shipment?
    status.in?(FULFILLMENT_SEQUENCE) || shipment.present?
  end

  def ensure_shipment!
    self.shipment = Shipment.find_or_create_by!(order_id: id)
  end

  # Walk one step through FULFILLMENT_SEQUENCE and append a matching
  # shipment event. Optional delivery_notes are stored on the shipment and
  # included in the "Delivered" event — no OTP/photo proof in this sprint.
  def advance!(admin_user: nil, delivery_notes: nil)
    nxt = next_status
    return false unless nxt

    transaction do
      ship = ensure_shipment!
      ship.update!(delivery_notes: delivery_notes) if delivery_notes.present?
      update!(status: nxt)
      ship.record_status_event!(nxt, admin_user: admin_user)
    end
    notify_fulfillment!(nxt)
    true
  end

  def carrier_name
    shipment&.carrier_name
  end

  def tracking_number
    shipment&.tracking_number
  end

  def delivery_events
    shipment ? shipment.events.chronological : ShipmentEvent.none
  end

  def delivered_at
    return nil unless delivered? || returned?

    shipment&.events&.delivered&.maximum(:occurred_at) || updated_at
  end

  def within_return_window?
    return false unless delivered_at

    delivered_at >= ReturnRequest.window_days.days.ago
  end

  def returnable?
    delivered? && within_return_window? && return_requests.open.none?
  end

  def current_return_request
    return_requests.recent.first
  end

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

  def subtotal
    subtotal_cents / 100.0
  end

  def shipping
    shipping_cents / 100.0
  end

  def total
    total_cents / 100.0
  end

  def notify!(event, extra = {})
    Notifications::Notify.call(
      event: event,
      recipient: customer,
      notifiable: self,
      payload: Notifications::Payload.for_order(self).merge(extra.stringify_keys)
    )
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
    notify!("order.cancelled")
    true
  end

  def notify_fulfillment!(status)
    case status.to_s
    when "shipped" then notify!("order.shipped")
    when "delivered"
      notify!("order.delivered")
      notify!("review.request")
    end
  end

  def generate_order_number
    loop do
      candidate = "ORD-#{SecureRandom.alphanumeric(10).upcase}"
      break self.order_number = candidate unless Order.exists?(order_number: candidate)
    end
  end
end
