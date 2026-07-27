# frozen_string_literal: true

module Admin
  # Manages merchandising banners (hero / promo / announcement).
  class BannersController < BaseController
    before_action -> { require_permission!("cms.read") }, only: :index
    before_action -> { require_permission!("cms.manage") }, only: %i[new create edit update destroy]
    before_action :set_banner, only: %i[edit update destroy]

    def index
      @banners = Banner.ordered
    end

    def new
      @banner = Banner.new(placement: params[:placement].presence || "hero", visible: true)
    end

    def create
      @banner = Banner.new(banner_params)
      if @banner.save
        redirect_to admin_banners_path, notice: "Banner created."
      else
        render :new, status: :unprocessable_content
      end
    end

    def edit; end

    def update
      if @banner.update(banner_params)
        redirect_to admin_banners_path, notice: "Banner updated."
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      @banner.destroy
      redirect_to admin_banners_path, notice: "Banner deleted."
    end

    private

    def set_banner
      @banner = Banner.find(params[:id])
    end

    def banner_params
      params.require(:banner).permit(
        :placement, :title, :subtitle, :image_url, :mobile_image_url, :link_url,
        :cta_label, :alt_text, :position, :visible, :starts_at, :ends_at
      )
    end
  end
end
