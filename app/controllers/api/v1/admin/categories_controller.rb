# frozen_string_literal: true

module Api
  module V1
    module Admin
      class CategoriesController < Api::V1::BaseController
        include AdminAuthentication

        before_action -> { authorize_permission!("categories.read") }, only: %i[index show]
        before_action -> { authorize_permission!("categories.manage") }, only: %i[create update destroy]

        def index
          render_success(Catalog::CategoryTree.new(scope: :admin).as_json)
        end

        def show
          category = Category.kept.find(params[:id])
          render_success(CategorySerializer.new(category).as_json)
        end

        def create
          category = Category.create!(category_params)
          render_success(CategorySerializer.new(category).as_json, status: :created)
        end

        def update
          category = Category.kept.find(params[:id])
          category.update!(category_params)
          render_success(CategorySerializer.new(category).as_json)
        end

        def destroy
          Category.kept.find(params[:id]).discard!
          render_success({ message: "Category archived." })
        end

        private

        def category_params
          params.require(:category).permit(
            :parent_id, :name, :slug, :description, :image_url, :position, :visible,
            :meta_title, :meta_description
          )
        end
      end
    end
  end
end
