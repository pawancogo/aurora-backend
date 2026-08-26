# frozen_string_literal: true

# Per-customer override for a catalog event + channel. Missing row = catalog default.
class NotificationPreference < ApplicationRecord
  belongs_to :customer

  validates :event_key, :channel, presence: true
  validates :event_key, uniqueness: { scope: [ :customer_id, :channel ] }
end
