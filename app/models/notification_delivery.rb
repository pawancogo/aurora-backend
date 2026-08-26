# frozen_string_literal: true

# One attempt to send a Notification over a single channel (email, sms, push).
class NotificationDelivery < ApplicationRecord
  belongs_to :notification

  enum :status, { pending: 0, sent: 1, failed: 2, skipped: 3 }, validate: true

  validates :channel, presence: true
end
