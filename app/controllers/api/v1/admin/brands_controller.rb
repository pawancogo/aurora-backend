# frozen_string_literal: true

module Api
  module V1
    module Admin
      class BrandsController < Api::V1::BaseController
        include AdminAuthentication

        before_action -> { authorize_permission!("brands.read") }, only: %i[index show]
        before_action -> { authorize_permission!("brands.manage") }, only: %i[create update destroy]

        def index
          render_success(Brand.kept.order(:name).map { |brand| BrandSerializer.new(brand).as_json })
        end

        def show
          brand = Brand.kept.find(params[:id])
          render_success(BrandSerializer.new(brand).as_json)
        end

        def create
          brand = Brand.create!(brand_params)
          render_success(BrandSerializer.new(brand).as_json, status: :created)
        end

        def update
          brand = Brand.kept.find(params[:id])
          brand.update!(brand_params)
          render_success(BrandSerializer.new(brand).as_json)
        end

        def destroy
          Brand.kept.find(params[:id]).discard!
          render_success({ message: "Brand archived." })
        end

        private

        def brand_params
          params.require(:brand).permit(:name, :slug, :description, :logo_url, :meta_title, :meta_description)
        end
      end
    end
  end
end
