# frozen_string_literal: true

class CustomerMailer < ApplicationMailer
  default from: -> { ENV.fetch("MAIL_FROM", "no-reply@aurora.test") }

  def verification_email(customer_id, token)
    @customer = Customer.find(customer_id)
    @verification_url = "#{frontend_origin}/verify-email?token=#{token}"
    mail(to: @customer.email, subject: "Verify your email address")
  end

  def password_reset_email(customer_id, token)
    @customer = Customer.find(customer_id)
    @reset_url = "#{frontend_origin}/reset-password?token=#{token}"
    mail(to: @customer.email, subject: "Reset your password")
  end

  private

  def frontend_origin
    ENV.fetch("FRONTEND_ORIGIN", "http://localhost:3000").split(",").first
  end
end
