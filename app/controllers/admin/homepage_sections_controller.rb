# frozen_string_literal: true

module Admin
  # Manages the configurable homepage blocks (hero / product_rail / category_grid
  # / rich_text / promo). Type-specific settings live in the jsonb `config`.
  class HomepageSectionsController < BaseController
    before_action -> { require_permission!("cms.read") }, only: :index
    before_action -> { require_permission!("cms.manage") }, only: %i[new create edit update destroy]
    before_action :set_section, only: %i[edit update destroy]

    def index
      @sections = HomepageSection.ordered
    end

    def new
      @section = HomepageSection.new(section_type: "product_rail", visible: true)
    end

    def create
      @section = HomepageSection.new(section_params)
      if @section.save
        redirect_to admin_homepage_sections_path, notice: "Homepage section created."
      else
        render :new, status: :unprocessable_content
      end
    end

    def edit; end

    def update
      if @section.update(section_params)
        redirect_to admin_homepage_sections_path, notice: "Homepage section updated."
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      @section.destroy
      redirect_to admin_homepage_sections_path, notice: "Homepage section deleted."
    end

    private

    def set_section
      @section = HomepageSection.find(params[:id])
    end

    def section_params
      permitted = params.require(:homepage_section)
                        .permit(:section_type, :title, :subtitle, :position, :visible, :starts_at, :ends_at)
      permitted[:config] = extract_config
      permitted
    end

    # Keep only the config keys we recognise, dropping blanks.
    def extract_config
      raw = params.dig(:homepage_section, :config)
      return {} unless raw.respond_to?(:permit)

      raw.permit(:source, :category_slug, :limit, :placement, :body)
         .to_h.reject { |_key, value| value.blank? }
    end
  end
end
