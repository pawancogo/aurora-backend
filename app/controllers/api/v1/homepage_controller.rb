# frozen_string_literal: true

module Api
  module V1
    # Aggregated homepage blocks for the storefront homepage.
    class HomepageController < BaseController
      # GET /api/v1/homepage
      def show
        render_success({ sections: Cms::Homepage.new.sections })
      end
    end
  end
end
