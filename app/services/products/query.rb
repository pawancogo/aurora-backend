# frozen_string_literal: true

module Products
  # Filters/sorts a product relation from request params.
  # category → includes the category and all its descendants.
  class Query
    SORTS = {
      "newest" => { created_at: :desc },
      "price_asc" => { price_cents: :asc },
      "price_desc" => { price_cents: :desc },
      "name" => { name: :asc }
    }.freeze
    DEFAULT_SORT = "newest"

    def initialize(relation = Product.all, params = {})
      @relation = relation
      @params = params
    end

    def call
      scope = @relation
      scope = scope.where(category_id: category.subtree_ids) if category
      scope = scope.where(brand_id: brand.id) if brand
      scope = scope.featured if truthy?(@params[:featured])
      scope = scope.new_arrivals if truthy?(@params[:new_arrival])
      scope = scope.best_sellers if truthy?(@params[:best_seller])
      scope = apply_price(scope)
      scope = apply_search(scope)
      scope.includes(:brand, :category, :product_images).order(sort_order)
    end

    private

    def category
      return @category if defined?(@category)

      @category = @params[:category].present? ? Category.kept.find_by(slug: @params[:category]) : nil
    end

    def brand
      return @brand if defined?(@brand)

      @brand = @params[:brand].present? ? Brand.kept.find_by(slug: @params[:brand]) : nil
    end

    def apply_price(scope)
      scope = scope.where(price_cents: (@params[:min_price].to_f * 100).to_i..) if @params[:min_price].present?
      scope = scope.where(price_cents: ..(@params[:max_price].to_f * 100).to_i) if @params[:max_price].present?
      scope
    end

    def apply_search(scope)
      return scope if @params[:q].blank?

      term = "%#{@params[:q].to_s.strip}%"
      scope.where(
        "products.name ILIKE :q OR products.sku ILIKE :q OR products.search_keywords ILIKE :q",
        q: term
      )
    end

    def sort_order
      SORTS.fetch(@params[:sort], SORTS[DEFAULT_SORT])
    end

    def truthy?(value)
      ActiveModel::Type::Boolean.new.cast(value)
    end
  end
end
