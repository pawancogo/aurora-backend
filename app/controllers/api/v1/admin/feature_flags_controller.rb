# frozen_string_literal: true

module Api
  module V1
    module Admin
      class FeatureFlagsController < Api::V1::BaseController
        include AdminAuthentication

        before_action -> { authorize_permission!("settings.read") }, only: %i[index]
        before_action -> { authorize_permission!("settings.manage") }, only: %i[create update destroy]

        def index
          render_success(FeatureFlag.order(:key).map { |flag| FeatureFlagSerializer.new(flag).as_json })
        end

        def create
          flag = FeatureFlag.create!(flag_params)
          render_success(FeatureFlagSerializer.new(flag).as_json, status: :created)
        end

        def update
          flag = FeatureFlag.find(params[:id])
          flag.update!(flag_params)
          render_success(FeatureFlagSerializer.new(flag).as_json)
        end

        def destroy
          FeatureFlag.find(params[:id]).destroy!
          render_success({ message: "Feature flag deleted." })
        end

        private

        def flag_params
          params.require(:feature_flag).permit(:key, :name, :description, :enabled)
        end
      end
    end
  end
end
