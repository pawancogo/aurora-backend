# frozen_string_literal: true

module Admin
  # Manages footer link columns (heading + a list of { label, url } links).
  class FooterSectionsController < BaseController
    before_action -> { require_permission!("cms.read") }, only: :index
    before_action -> { require_permission!("cms.manage") }, only: %i[new create edit update destroy]
    before_action :set_section, only: %i[edit update destroy]

    def index
      @sections = FooterSection.ordered
    end

    def new
      @section = FooterSection.new(visible: true)
    end

    def create
      @section = FooterSection.new(section_params)
      if @section.save
        redirect_to admin_footer_sections_path, notice: "Footer column created."
      else
        render :new, status: :unprocessable_content
      end
    end

    def edit; end

    def update
      if @section.update(section_params)
        redirect_to admin_footer_sections_path, notice: "Footer column updated."
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      @section.destroy
      redirect_to admin_footer_sections_path, notice: "Footer column deleted."
    end

    private

    def set_section
      @section = FooterSection.find(params[:id])
    end

    def section_params
      permitted = params.require(:footer_section).permit(:heading, :position, :visible)
      permitted[:links] = extract_links
      permitted
    end

    # Links arrive as footer_section[links][<i>][label|url]; keep non-blank pairs.
    def extract_links
      raw = params.dig(:footer_section, :links)
      rows = raw.respond_to?(:values) ? raw.values : Array(raw)
      rows.filter_map do |row|
        label = row[:label].to_s.strip
        url = row[:url].to_s.strip
        { "label" => label, "url" => url } if label.present? && url.present?
      end
    end
  end
end
