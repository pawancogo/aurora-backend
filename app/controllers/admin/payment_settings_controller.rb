# frozen_string_literal: true

module Admin
  # Single-purpose screen (no index/collection) for the one payments-related
  # setting we expose in the admin: the Razorpay Dashboard payment-methods
  # config ID passed to Checkout.js. Blank means "no config" — the frontend
  # falls back to its hardcoded card+UPI-only default.
  class PaymentSettingsController < BaseController
    before_action -> { require_permission!("settings.manage") }

    def show
      @config_id = SiteSetting.get("razorpay.config_id")
    end

    def update
      setting = SiteSetting.find_or_initialize_by(key: "razorpay.config_id")
      setting.category = "payments" if setting.new_record?
      setting.update!(value: params[:razorpay_config_id].to_s.strip)
      redirect_to admin_payment_settings_path, notice: "Payment settings updated."
    end
  end
end
