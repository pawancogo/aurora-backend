# frozen_string_literal: true

module Notifications
  module Channels
    # Contract for a delivery adapter. Subclass, implement `#key`, `#enabled?`,
    # and `#deliver(delivery)`, then `Registry.register`.
    class Base
      def key
        raise NotImplementedError, "#{self.class}#key"
      end

      def enabled?
        false
      end

      def deliver(_delivery)
        raise NotImplementedError, "#{self.class}#deliver"
      end
    end
  end
end
