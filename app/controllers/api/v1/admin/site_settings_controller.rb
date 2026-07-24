# frozen_string_literal: true

module Api
  module V1
    module Admin
      class SiteSettingsController < Api::V1::BaseController
        include AdminAuthentication

        before_action -> { authorize_permission!("settings.read") }, only: %i[index show]
        before_action -> { authorize_permission!("settings.manage") }, only: %i[create update destroy]

        def index
          settings = SiteSetting.order(:category, :key)
          render_success(settings.map { |setting| SiteSettingSerializer.new(setting).as_json })
        end

        def show
          setting = SiteSetting.find(params[:id])
          render_success(SiteSettingSerializer.new(setting).as_json)
        end

        def create
          setting = SiteSetting.new(setting_attributes)
          setting.save!
          render_success(SiteSettingSerializer.new(setting).as_json, status: :created)
        end

        def update
          setting = SiteSetting.find(params[:id])
          setting.update!(setting_attributes.except(:key))
          render_success(SiteSettingSerializer.new(setting).as_json)
        end

        def destroy
          SiteSetting.find(params[:id]).destroy!
          render_success({ message: "Setting deleted." })
        end

        private

        # `value` is jsonb (any JSON), so it's assigned raw rather than through permit's scalar filter.
        def setting_attributes
          scalars = params.require(:site_setting).permit(:key, :value_type, :category, :description, :public_read)
          scalars.to_h.symbolize_keys.merge(value: params.dig(:site_setting, :value))
        end
      end
    end
  end
end
