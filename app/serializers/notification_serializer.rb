# frozen_string_literal: true

class NotificationSerializer
  def self.collection(notifications)
    notifications.map { |notification| new(notification).as_json }
  end

  def initialize(notification)
    @notification = notification
  end

  def as_json(*)
    {
      id: @notification.id,
      event_key: @notification.event_key,
      title: @notification.title,
      body: @notification.body,
      url: @notification.url,
      read: @notification.read?,
      read_at: @notification.read_at,
      created_at: @notification.created_at
    }
  end
end
