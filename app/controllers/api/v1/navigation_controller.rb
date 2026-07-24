# frozen_string_literal: true

module Api
  module V1
    class NavigationController < BaseController
      # GET /api/v1/navigation?location=header
      # Public, cached, visible + currently-scheduled items only.
      def index
        location = params[:location].presence || "header"
        render_success(Navigation::TreeCache.fetch(location))
      end
    end
  end
end
