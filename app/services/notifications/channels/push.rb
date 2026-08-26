# frozen_string_literal: true

module Notifications
  module Channels
    # Web-push adapter stub. Enable with VAPID_PUBLIC_KEY (and secret) later.
    class Push < Base
      def key
        "push"
      end

      def enabled?
        ENV["VAPID_PUBLIC_KEY"].present?
      end

      def deliver(delivery)
        raise "Push is not configured" unless enabled?

        notification = delivery.notification
        Rails.logger.info(
          "[notifications:push] event=#{notification.event_key} customer=#{notification.customer_id}"
        )
      end
    end
  end
end
