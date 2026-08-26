# frozen_string_literal: true

module Notifications
  module Channels
    # Real email via ActionMailer (SMTP when SMTP_ADDRESS is set; otherwise
    # the environment default — file in development, test adapter in test).
    class Email < Base
      def key
        "email"
      end

      def enabled?
        true
      end

      def deliver(delivery)
        NotificationMailer.event_email(delivery.notification_id).deliver_now
      end
    end
  end
end
