# frozen_string_literal: true

module Api
  module V1
    # Site-wide chrome: the header announcement bar + footer columns.
    class SiteController < BaseController
      # GET /api/v1/site
      def show
        cms = Cms::Homepage.new
        render_success({ announcement: cms.announcement, footer: cms.footer })
      end
    end
  end
end
