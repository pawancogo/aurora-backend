# frozen_string_literal: true

module Api
  module V1
    # Public read of published CMS static pages, by slug.
    class PagesController < BaseController
      # GET /api/v1/pages/:id  (id = slug)
      def show
        page = StaticPage.published.find_by!(slug: params[:id])
        render_success({
          slug: page.slug,
          title: page.title,
          body: page.body,
          meta_title: page.meta_title,
          meta_description: page.meta_description,
          updated_at: page.updated_at
        })
      end
    end
  end
end
