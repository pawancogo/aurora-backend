# frozen_string_literal: true

module Admin
  # Single-purpose screen (no index/collection) for the small set of general
  # site settings staff actually need to touch: store name, tagline, support
  # email, and currency code. Same singleton show/update shape as
  # Admin::PaymentSettingsController.
  class GeneralSettingsController < BaseController
    before_action -> { require_permission!("settings.manage") }

    KEYS = %w[site.name site.tagline site.support_email site.currency].freeze

    def show
      @values = KEYS.index_with { |key| SiteSetting.get(key) }
    end

    def update
      settings_params.each do |key, value|
        setting = SiteSetting.find_or_initialize_by(key: key)
        if setting.new_record?
          setting.category = "general"
          setting.public_read = true
        end
        setting.update!(value: value.to_s.strip)
      end
      redirect_to admin_general_settings_path, notice: "Settings updated."
    end

    private

    def settings_params
      params.permit(*KEYS)
    end
  end
end
