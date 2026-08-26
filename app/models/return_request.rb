# frozen_string_literal: true

# A shopper's request to send items back from a delivered order. Staff
# approve/reject, mark the parcel received (which restocks), then complete
# (which flags a refund for refund-resolution RMAs). Not the CMS policy page.
class ReturnRequest < ApplicationRecord
  include SearchManager

  search_manager on: %i[rma_number], aggs_on: %i[status resolution]

  class Error < StandardError; end

  DEFAULT_WINDOW_DAYS = 7
  OPEN_STATUSES = %w[requested approved received].freeze

  belongs_to :order
  belongs_to :customer
  has_many :return_items, dependent: :destroy

  has_paper_trail

  enum :status, {
    requested: 0,
    approved: 1,
    rejected: 2,
    received: 3,
    completed: 4
  }, validate: true

  enum :resolution, { refund: 0, exchange: 1 }, validate: true

  before_validation :generate_rma_number, on: :create

  validates :rma_number, presence: true, uniqueness: true
  validates :reason, presence: true, length: { maximum: 500 }
  validates :admin_notes, length: { maximum: 2000 }, allow_blank: true

  scope :open, -> { where(status: OPEN_STATUSES) }
  scope :recent, -> { order(id: :desc) }

  def self.window_days
    days = SiteSetting.get("returns.window_days", DEFAULT_WINDOW_DAYS).to_i
    days.positive? ? days : DEFAULT_WINDOW_DAYS
  end

  def self.request!(order:, reason:, resolution: :refund, items: nil)
    raise Error, "This order can't be returned." unless order.returnable?

    request = nil
    transaction do
      request = create!(
        order: order,
        customer: order.customer,
        reason: reason.to_s.strip,
        resolution: resolution.presence || :refund
      )
      request.add_lines!(items)
    end
    request.notify!("return.requested")
    request
  end

  def add_lines!(items)
    lines = normalize_lines(items)
    raise Error, "Select at least one item to return." if lines.empty?

    lines.each do |order_item, quantity|
      return_items.create!(order_item: order_item, quantity: quantity)
    end
  end

  def approve!(note: nil)
    raise Error, "Only a requested return can be approved." unless requested?

    update!(status: :approved, decided_at: Time.current, admin_notes: note.presence || admin_notes)
    notify!("return.approved")
  end

  def reject!(note:)
    raise Error, "Only a requested return can be rejected." unless requested?
    raise Error, "Please add a note explaining the rejection." if note.blank?

    update!(status: :rejected, decided_at: Time.current, admin_notes: note)
    notify!("return.rejected")
  end

  def receive!(admin_user: nil)
    raise Error, "Mark the return as approved before receiving it." unless approved?

    transaction do
      return_items.includes(order_item: { product_variant: :inventory_item }).each do |item|
        inventory_item = item.order_item.product_variant&.inventory_item
        next unless inventory_item

        Inventory::AdjustStock.new(
          inventory_item: inventory_item,
          quantity: item.quantity,
          reason: "return",
          actor: admin_user,
          note: "RMA #{rma_number}"
        ).call
        item.update!(restocked: true)
      end
      update!(status: :received, received_at: Time.current)
    end
  end

  def complete!
    raise Error, "Receive the return before completing it." unless received?

    transaction do
      if refund?
        order.payments.captured.each { |payment| payment.update!(status: :refund_pending) }
        order.update!(status: :returned)
      end
      update!(status: :completed, completed_at: Time.current)
    end
    notify!("return.completed")
  end

  def notify!(event)
    Notifications::Notify.call(
      event: event,
      recipient: customer,
      notifiable: self,
      payload: Notifications::Payload.for_return(self)
    )
  end

  private

  def generate_rma_number
    return if rma_number.present?

    loop do
      candidate = "RMA-#{SecureRandom.alphanumeric(10).upcase}"
      break self.rma_number = candidate unless self.class.exists?(rma_number: candidate)
    end
  end

  def normalize_lines(items)
    if items.blank?
      return order.order_items.map { |order_item| [ order_item, order_item.quantity ] }
    end

    Array(items).filter_map do |raw|
      attrs = raw.respond_to?(:to_unsafe_h) ? raw.to_unsafe_h : raw
      attrs = attrs.with_indifferent_access
      order_item = order.order_items.find_by(id: attrs[:order_item_id])
      raise Error, "One of those items isn't on this order." unless order_item

      quantity = attrs[:quantity].to_i
      raise Error, "Return quantity must be at least 1." if quantity < 1
      raise Error, "Can't return more of #{order_item.product_name} than was ordered." if quantity > order_item.quantity

      [ order_item, quantity ]
    end
  end
end
