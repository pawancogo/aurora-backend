# frozen_string_literal: true

module Admin
  class CategoriesController < BaseController
    before_action -> { require_permission!("categories.read") }, only: :index
    before_action -> { require_permission!("categories.manage") }, only: %i[new create edit update destroy]
    before_action :set_category, only: %i[edit update destroy]

    def index
      @filtering = params[:q].present? || params[:visible].present?
      if @filtering
        @results = Category.search(params, scope: Category.kept.order(:name)).records
      else
        @ordered = ordered_with_depth(Category.kept.order(:position, :name).to_a)
      end
    end

    def new
      @category = Category.new(visible: true)
    end

    def create
      @category = Category.new(category_params)
      if @category.save
        redirect_to admin_categories_path, notice: "Category “#{@category.name}” created."
      else
        render :new, status: :unprocessable_content
      end
    end

    def edit; end

    def update
      if @category.update(category_params)
        redirect_to admin_categories_path, notice: "Category “#{@category.name}” updated."
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      @category.discard!
      redirect_to admin_categories_path, notice: "Category archived."
    end

    private

    def set_category
      @category = Category.kept.find(params[:id])
    end

    def category_params
      params.require(:category).permit(
        :name, :slug, :parent_id, :description, :image_url, :position, :visible,
        :meta_title, :meta_description
      )
    end

    def ordered_with_depth(all, parent_id = nil, depth = 0, acc = [])
      all.select { |c| c.parent_id == parent_id }.each do |category|
        acc << [ category, depth ]
        ordered_with_depth(all, category.id, depth + 1, acc)
      end
      acc
    end
  end
end
