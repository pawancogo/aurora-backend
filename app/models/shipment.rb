# frozen_string_literal: true

# Manual shipment for an order: carrier/tracking the shopper sees, packing
# notes for the warehouse, and a timeline of events (status steps plus
# out-for-delivery / free-form notes). One per order — split shipments are
# a later sprint.
class Shipment < ApplicationRecord
  belongs_to :order
  has_many :events, class_name: "ShipmentEvent", dependent: :destroy

  has_paper_trail

  validates :order_id, uniqueness: true
  validates :carrier_name, :tracking_number, length: { maximum: 100 }, allow_blank: true
  validates :packing_notes, :delivery_notes, length: { maximum: 2000 }, allow_blank: true

  before_validation :blank_to_nil

  STATUS_EVENT_TYPES = {
    "accepted" => :accepted,
    "ready_to_ship" => :packed,
    "shipped" => :shipped,
    "delivered" => :delivered
  }.freeze

  def apply_details!(attrs)
    transaction do
      tracking_was_blank = tracking_number.blank?
      assign_attributes(attrs)
      save!

      if tracking_was_blank && tracking_number.present?
        events.create!(
          event_type: :note,
          description: [ "Tracking", carrier_name, tracking_number ].compact_blank.join(" · "),
          occurred_at: Time.current
        )
      end
    end
  end

  def record_status_event!(status, admin_user: nil)
    type = STATUS_EVENT_TYPES[status.to_s]
    return unless type
    return if events.exists?(event_type: type)

    events.create!(
      event_type: type,
      description: description_for(status),
      occurred_at: Time.current,
      admin_user: admin_user
    )
  end

  private

  def blank_to_nil
    self.carrier_name = carrier_name.presence
    self.tracking_number = tracking_number.presence
    self.packing_notes = packing_notes.presence
    self.delivery_notes = delivery_notes.presence
  end

  def description_for(status)
    case status.to_s
    when "accepted"
      "Accepted for fulfillment"
    when "ready_to_ship"
      "Packed and ready to ship"
    when "shipped"
      [ "Shipped", carrier_name, tracking_number ].compact_blank.join(" · ")
    when "delivered"
      delivery_notes.present? ? "Delivered — #{delivery_notes}" : "Delivered"
    else
      status.to_s.humanize
    end
  end
end
