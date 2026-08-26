# frozen_string_literal: true

module Notifications
  # Preference-based suppression. Transactional email cannot be turned off.
  # Optional email (review reminders) follows email_marketing + per-event rows.
  # SMS/push default off until the customer opts in (and the adapter is live).
  class Preferences
    def self.allows?(customer, event_key, channel)
      new(customer).allows?(event_key, channel)
    end

    def initialize(customer)
      @customer = customer
    end

    def allows?(event_key, channel)
      channel = channel.to_s
      definition = Catalog.fetch!(event_key)

      return true if channel == "in_app"
      return true if channel == "email" && definition[:transactional]
      return false if channel == "email" && !@customer.email_marketing?

      pref = @customer.notification_preferences.find_by(event_key: event_key.to_s, channel: channel)
      return pref.enabled if pref

      default_enabled?(definition, channel)
    end

    def catalog_for_api
      Catalog.keys.map do |key|
        definition = Catalog.fetch!(key)
        {
          event_key: key,
          title: definition[:title],
          transactional: definition[:transactional],
          channels: definition[:channels].map do |channel|
            {
              channel: channel.to_s,
              enabled: allows?(key, channel),
              locked: channel.to_s == "email" && definition[:transactional]
            }
          end
        }
      end
    end

    def upsert!(event_key:, channel:, enabled:)
      definition = Catalog.fetch!(event_key)
      channel = channel.to_s
      if channel == "email" && definition[:transactional]
        raise ArgumentError, "Transactional email cannot be turned off"
      end

      record = @customer.notification_preferences.find_or_initialize_by(event_key: event_key.to_s, channel: channel)
      record.enabled = ActiveModel::Type::Boolean.new.cast(enabled)
      record.save!
      record
    end

    private

    def default_enabled?(_definition, channel)
      return false if %w[sms push].include?(channel)

      true
    end
  end
end
