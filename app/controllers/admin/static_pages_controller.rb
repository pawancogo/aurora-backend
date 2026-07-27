# frozen_string_literal: true

module Admin
  # Manages CMS static pages (About, Contact, Privacy, …).
  class StaticPagesController < BaseController
    before_action -> { require_permission!("cms.read") }, only: :index
    before_action -> { require_permission!("cms.manage") }, only: %i[new create edit update destroy]
    before_action :set_page, only: %i[edit update destroy]

    def index
      result = StaticPage.search(params, scope: StaticPage.ordered)
      @facets = result.facets
      @pages = result.records
    end

    def new
      @page = StaticPage.new(published: false)
    end

    def create
      @page = StaticPage.new(page_params)
      if @page.save
        redirect_to admin_static_pages_path, notice: "Page “#{@page.title}” created."
      else
        render :new, status: :unprocessable_content
      end
    end

    def edit; end

    def update
      if @page.update(page_params)
        redirect_to admin_static_pages_path, notice: "Page “#{@page.title}” updated."
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      @page.destroy
      redirect_to admin_static_pages_path, notice: "Page deleted."
    end

    private

    def set_page
      @page = StaticPage.find(params[:id])
    end

    def page_params
      params.require(:static_page).permit(:title, :slug, :body, :published, :meta_title, :meta_description, :position)
    end
  end
end
