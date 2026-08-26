# frozen_string_literal: true

module Notifications
  # Maps channel keys ("email", "sms", "push") to adapter instances.
  # New services register here; Notify never hard-codes a provider.
  class Registry
    class << self
      def adapters
        @adapters ||= {}
      end

      def register(adapter)
        adapters[adapter.key.to_s] = adapter
        adapter
      end

      def fetch(key)
        adapters.fetch(key.to_s) { raise ArgumentError, "Unknown notification channel: #{key}" }
      end

      def fetch?(key)
        adapters[key.to_s]
      end

      def reset!
        @adapters = {}
      end
    end
  end
end
