# frozen_string_literal: true

module Notifications
  # Creates the in-app inbox row, then fans out to every enabled channel
  # adapter registered for the event. Idempotent per (customer, event, notifiable).
  class Notify
    def self.call(...)
      new(...).call
    end

    def initialize(event:, recipient:, notifiable:, payload: {})
      @event = event.to_s
      @recipient = recipient
      @notifiable = notifiable
      @payload = payload.stringify_keys
    end

    def call
      definition = Catalog.fetch!(@event)
      notification = find_or_create_inbox!(definition)
      fan_out(notification, definition)
      notification
    end

    private

    def find_or_create_inbox!(definition)
      attrs = {
        customer: @recipient,
        event_key: @event,
        notifiable: @notifiable
      }
      existing = Notification.find_by(attrs)
      return existing if existing

      Notification.create!(
        attrs.merge(
          title: Catalog.interpolate(definition[:title], @payload),
          body: Catalog.interpolate(definition[:body], @payload),
          url: Catalog.interpolate(definition[:url_template], @payload).presence,
          payload: @payload
        )
      )
    rescue ActiveRecord::RecordNotUnique
      Notification.find_by!(attrs)
    end

    def fan_out(notification, definition)
      Array(definition[:channels]).each do |channel|
        next if channel.to_sym == :in_app
        next unless Preferences.allows?(@recipient, @event, channel)

        adapter = Registry.fetch?(channel)
        next unless adapter&.enabled?

        delivery = notification.deliveries.find_or_initialize_by(channel: channel.to_s)
        next if delivery.sent? || (delivery.persisted? && delivery.pending?)

        delivery.status = :pending
        delivery.error = nil
        delivery.save!
        enqueue_delivery(delivery)
      end
    end

    def enqueue_delivery(delivery)
      Notifications::DeliverJob.perform_later(delivery.id)
    rescue RedisClient::CannotConnectError
      Rails.logger.warn("[notifications] Redis unavailable; delivering #{delivery.channel} inline")
      Notifications::DeliverJob.perform_now(delivery.id)
    end
  end
end
