# frozen_string_literal: true

module Admin
  class BrandsController < BaseController
    before_action -> { require_permission!("brands.read") }, only: :index
    before_action -> { require_permission!("brands.manage") }, only: %i[new create edit update destroy]
    before_action :set_brand, only: %i[edit update destroy]

    def index
      @brands = Brand.search(params, scope: Brand.kept.order(:name)).records
    end

    def new
      @brand = Brand.new
    end

    def create
      @brand = Brand.new(brand_params)
      if @brand.save
        redirect_to admin_brands_path, notice: "Brand “#{@brand.name}” created."
      else
        render :new, status: :unprocessable_content
      end
    end

    def edit; end

    def update
      if @brand.update(brand_params)
        redirect_to admin_brands_path, notice: "Brand “#{@brand.name}” updated."
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      @brand.discard!
      redirect_to admin_brands_path, notice: "Brand archived."
    end

    private

    def set_brand
      @brand = Brand.kept.find(params[:id])
    end

    def brand_params
      params.require(:brand).permit(:name, :slug, :description, :logo_url, :meta_title, :meta_description)
    end
  end
end
