# frozen_string_literal: true

module Api
  module V1
    class NotificationsController < BaseController
      include CustomerAuthentication

      before_action :authenticate_customer!

      # GET /api/v1/notifications
      def index
        notifications, meta = paginate(current_customer.notifications.recent)
        meta = meta.merge(unread_count: current_customer.notifications.unread.count)
        render_success(NotificationSerializer.collection(notifications), meta: meta)
      end

      # GET /api/v1/notifications/unread_count
      def unread_count
        render_success({ unread_count: current_customer.notifications.unread.count })
      end

      # PATCH /api/v1/notifications/:id/read
      def read
        notification = current_customer.notifications.find(params[:id])
        notification.mark_read!
        render_success(NotificationSerializer.new(notification).as_json)
      end

      # POST /api/v1/notifications/read_all
      def read_all
        current_customer.notifications.unread.update_all(read_at: Time.current)
        render_success({ unread_count: 0 })
      end
    end
  end
end
