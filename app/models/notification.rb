# frozen_string_literal: true

# In-app inbox row for one customer + one event on a notifiable (order, RMA, …).
# Channel fan-out (email today; SMS/push later) lives on NotificationDelivery.
class Notification < ApplicationRecord
  belongs_to :customer
  belongs_to :notifiable, polymorphic: true
  has_many :deliveries, class_name: "NotificationDelivery", dependent: :destroy

  validates :event_key, :title, :body, presence: true

  scope :recent, -> { order(created_at: :desc, id: :desc) }
  scope :unread, -> { where(read_at: nil) }

  def read?
    read_at.present?
  end

  def mark_read!
    update!(read_at: Time.current) if read_at.nil?
  end
end
