# frozen_string_literal: true

# When SMTP credentials are present, deliver real email via SMTP in every environment
# EXCEPT test (tests must never send real mail). Without credentials, environment
# defaults apply (development -> :file, test -> :test).
#
# Runs after `action_mailer.set_configs`, so setting ActionMailer::Base directly here
# reliably overrides the environment defaults.
if ENV["SMTP_ADDRESS"].present? && !Rails.env.test?
  ActionMailer::Base.delivery_method = :smtp
  ActionMailer::Base.perform_deliveries = true
  ActionMailer::Base.raise_delivery_errors = true
  ActionMailer::Base.smtp_settings = {
    address: ENV["SMTP_ADDRESS"],
    port: ENV.fetch("SMTP_PORT", "587").to_i,
    domain: ENV["SMTP_DOMAIN"],
    user_name: ENV["SMTP_USERNAME"],
    password: ENV["SMTP_PASSWORD"],
    authentication: ENV.fetch("SMTP_AUTHENTICATION", "plain").to_sym,
    enable_starttls_auto: ActiveModel::Type::Boolean.new.cast(ENV.fetch("SMTP_ENABLE_STARTTLS_AUTO", "true"))
  }
end
