# frozen_string_literal: true

module Api
  module V1
    class BrandsController < BaseController
      # GET /api/v1/brands
      def index
        render_success(Brand.kept.order(:name).map { |brand| BrandSerializer.new(brand).as_json })
      end

      # GET /api/v1/brands/:slug
      def show
        brand = Brand.kept.find_by!(slug: params[:id])
        render_success(BrandSerializer.new(brand).as_json)
      end
    end
  end
end
