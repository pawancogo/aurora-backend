# frozen_string_literal: true

module Notifications
  module Channels
    # SMS adapter stub. Enable with SMS_PROVIDER (e.g. twilio) + credentials;
    # until then Notify skips this channel so orders don't record empty skips.
    class Sms < Base
      def key
        "sms"
      end

      def enabled?
        ENV["SMS_PROVIDER"].present?
      end

      def deliver(delivery)
        raise "SMS is not configured" unless enabled?

        notification = delivery.notification
        Rails.logger.info(
          "[notifications:sms] provider=#{ENV['SMS_PROVIDER']} event=#{notification.event_key} " \
          "to=#{notification.customer.phone} body=#{notification.body}"
        )
      end
    end
  end
end
