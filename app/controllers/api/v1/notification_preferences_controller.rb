# frozen_string_literal: true

module Api
  module V1
    class NotificationPreferencesController < BaseController
      include CustomerAuthentication

      before_action :authenticate_customer!

      # GET /api/v1/notification_preferences
      def show
        render_success(payload)
      end

      # PATCH /api/v1/notification_preferences
      def update
        prefs = Notifications::Preferences.new(current_customer)
        if params.key?(:email_marketing)
          current_customer.update!(email_marketing: ActiveModel::Type::Boolean.new.cast(params[:email_marketing]))
        end
        Array(params[:preferences]).each do |row|
          attrs = row.respond_to?(:permit) ? row.permit(:event_key, :channel, :enabled) : row
          prefs.upsert!(
            event_key: attrs[:event_key] || attrs["event_key"],
            channel: attrs[:channel] || attrs["channel"],
            enabled: attrs[:enabled].nil? ? attrs["enabled"] : attrs[:enabled]
          )
        end
        render_success(payload)
      rescue ArgumentError => e
        render_error(code: "invalid_preference", message: e.message, status: :unprocessable_content)
      end

      private

      def payload
        {
          email_marketing: current_customer.email_marketing?,
          events: Notifications::Preferences.new(current_customer).catalog_for_api
        }
      end
    end
  end
end
