# frozen_string_literal: true

module Notifications
  class DeliverJob < ApplicationJob
    queue_as :default

    def perform(delivery_id)
      delivery = NotificationDelivery.find(delivery_id)
      return if delivery.sent?

      adapter = Registry.fetch(delivery.channel)
      adapter.deliver(delivery)
      delivery.update!(status: :sent, sent_at: Time.current, error: nil)
    rescue ActiveRecord::RecordNotFound
      Rails.logger.warn("[notifications] delivery #{delivery_id} gone")
    rescue StandardError => e
      delivery&.update!(status: :failed, error: e.message)
      Rails.logger.error("[notifications] delivery #{delivery_id} failed: #{e.class}: #{e.message}")
    end
  end
end
