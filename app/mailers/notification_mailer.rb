# frozen_string_literal: true

class NotificationMailer < ApplicationMailer
  default from: -> { ENV.fetch("MAIL_FROM", "no-reply@aurora.test") }
  layout false

  def event_email(notification_id)
    @notification = Notification.find(notification_id)
    @customer = @notification.customer
    @cta_url = absolute_url(@notification.url)
    @preferences_url = "#{frontend_origin}/account/notifications"
    @unsubscribe_url = "#{frontend_origin}/unsubscribe?token=#{@customer.unsubscribe_token}"
    @optional = !Notifications::Catalog.transactional?(@notification.event_key)
    mail(to: @customer.email, subject: @notification.title)
  end

  private

  def frontend_origin
    ENV.fetch("FRONTEND_ORIGIN", "http://localhost:3000").split(",").first
  end

  def absolute_url(path)
    return frontend_origin if path.blank?

    path.start_with?("http") ? path : "#{frontend_origin}#{path}"
  end
end
