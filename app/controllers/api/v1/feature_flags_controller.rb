# frozen_string_literal: true

module Api
  module V1
    class FeatureFlagsController < BaseController
      # GET /api/v1/feature_flags — { key => enabled } map.
      def index
        render_success(FeatureFlag.to_map)
      end
    end
  end
end
