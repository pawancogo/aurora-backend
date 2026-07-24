# frozen_string_literal: true

module Api
  module V1
    class SettingsController < BaseController
      # GET /api/v1/settings — publicly-readable settings as a { key => value } map.
      def index
        render_success(SiteSetting.to_map(SiteSetting.publicly_readable))
      end
    end
  end
end
