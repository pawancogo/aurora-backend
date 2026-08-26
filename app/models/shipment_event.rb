# frozen_string_literal: true

# Immutable timeline entry on a shipment. Status steps are written when an
# order is advanced; staff can also log out-for-delivery and free-form notes.
class ShipmentEvent < ApplicationRecord
  belongs_to :shipment
  belongs_to :admin_user, optional: true

  enum :event_type, {
    accepted: 0,
    packed: 1,
    shipped: 2,
    out_for_delivery: 3,
    delivered: 4,
    note: 5
  }, validate: true

  validates :description, presence: true, length: { maximum: 500 }
  validates :occurred_at, presence: true

  before_validation { self.occurred_at ||= Time.current }

  scope :chronological, -> { order(occurred_at: :asc, id: :asc) }
end
