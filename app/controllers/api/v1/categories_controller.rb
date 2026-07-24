# frozen_string_literal: true

module Api
  module V1
    class CategoriesController < BaseController
      # GET /api/v1/categories — nested visible tree.
      def index
        render_success(Catalog::CategoryTree.new(scope: :public).as_json)
      end

      # GET /api/v1/categories/:slug — with breadcrumb + immediate children.
      def show
        category = Category.kept.visible.find_by!(slug: params[:id])
        render_success({
                         category: CategorySerializer.new(category).as_json,
                         breadcrumb: category.ancestors.map { |c| { name: c.name, slug: c.slug } },
                         children: category.children.visible.ordered.map { |c| CategorySerializer.new(c).as_json }
                       })
      end
    end
  end
end
