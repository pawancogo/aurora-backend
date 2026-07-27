# frozen_string_literal: true

module Products
  # Faceted product search for the storefront listing/category pages.
  #
  #   result = Products::Search.new(Product.kept.live, params).call
  #   result.records  # filtered, sorted relation (caller paginates)
  #   result.facets   # { brands:, attributes:, price:, availability: } with counts
  #
  # Filters: category (subtree), brand (slug), price (min/max), q (name/sku/
  # keywords), flags (featured/new_arrival/best_seller), in_stock, and per-option
  # attributes (attr[<code>]=<value_codes>, e.g. attr[color]=red,blue).
  #
  # Facets are counted against the *browse context* (category + q + price + flags)
  # so choosing a brand / attribute / availability option never hides the others.
  class Search
    Result = Struct.new(:records, :facets, keyword_init: true)

    SORTS = {
      "newest" => { created_at: :desc },
      "price_asc" => { price_cents: :asc },
      "price_desc" => { price_cents: :desc },
      "name" => { name: :asc }
    }.freeze
    DEFAULT_SORT = "newest"

    def initialize(scope = Product.kept.live, params = {})
      @scope = scope
      @params = params
    end

    def call
      context = context_scope
      records = refine(context).includes(:brand, :category, :product_images).order(sort_order)
      Result.new(records: records, facets: build_facets(context))
    end

    private

    # Browse context: everything except the facetable dimensions (brand,
    # attributes, availability).
    def context_scope
      scope = @scope
      scope = scope.where(category_id: category.subtree_ids) if category
      scope = scope.featured if truthy?(:featured)
      scope = scope.new_arrivals if truthy?(:new_arrival)
      scope = scope.best_sellers if truthy?(:best_seller)
      scope = apply_price(scope)
      apply_search(scope)
    end

    def refine(scope)
      scope = scope.where(brand_id: brand.id) if brand
      selected_attributes.each do |code, value_codes|
        scope = scope.where(id: product_ids_with_attribute(code, value_codes))
      end
      scope = scope.where(id: in_stock_product_ids) if truthy?(:in_stock)
      scope
    end

    # --- filters ---------------------------------------------------------------

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

      term = "%#{Product.sanitize_sql_like(@params[:q].to_s.strip)}%"
      scope.where("products.name ILIKE :q OR products.sku ILIKE :q OR products.search_keywords ILIKE :q", q: term)
    end

    # { "color" => ["red","blue"], "size" => ["m"] } from attr[<code>]=v or v1,v2.
    # Handles both plain hashes and ActionController::Parameters.
    def selected_attributes
      raw = @params[:attr]
      raw = raw.to_unsafe_h if raw.respond_to?(:to_unsafe_h)
      return {} unless raw.respond_to?(:each_pair)

      raw.each_with_object({}) do |(code, values), acc|
        codes = Array(values).flat_map { |v| v.to_s.split(",") }.map(&:strip).reject(&:blank?)
        acc[code.to_s] = codes if codes.any?
      end
    end

    def product_ids_with_attribute(code, value_codes)
      ProductVariant
        .joins(variant_option_values: { attribute_value: :product_attribute })
        .where(product_attributes: { code: code }, attribute_values: { code: value_codes })
        .select(:product_id)
    end

    def in_stock_product_ids
      ProductVariant.purchasable.joins(:inventory_item)
                    .where("(inventory_items.on_hand - inventory_items.reserved) > 0 OR inventory_items.backorderable")
                    .select(:product_id)
    end

    def sort_order
      SORTS.fetch(@params[:sort], SORTS[DEFAULT_SORT])
    end

    def truthy?(key)
      ActiveModel::Type::Boolean.new.cast(@params[key])
    end

    # --- facets ----------------------------------------------------------------

    def build_facets(context)
      ids = context.reorder(nil).select(:id)
      {
        brands: brand_facets(ids),
        attributes: attribute_facets(ids),
        price: price_facet(context),
        availability: availability_facet(ids)
      }
    end

    def brand_facets(ids)
      Product.where(id: ids).joins(:brand)
             .group("brands.slug", "brands.name").count
             .map { |(slug, name), count| { slug: slug, name: name, count: count } }
             .sort_by { |brand| -brand[:count] }
    end

    def attribute_facets(ids)
      counts = ProductVariant.where(product_id: ids)
                             .joins(variant_option_values: { attribute_value: :product_attribute })
                             .where(product_attributes: { filterable: true })
                             .group("product_attributes.position", "product_attributes.name", "product_attributes.code",
                                    "attribute_values.position", "attribute_values.value", "attribute_values.code")
                             .count("DISTINCT product_variants.product_id")

      grouped = {}
      counts.each do |(_pa_pos, pa_name, pa_code, _av_pos, av_value, av_code), count|
        entry = (grouped[pa_code] ||= { name: pa_name, code: pa_code, values: [] })
        entry[:values] << { value: av_value, code: av_code, count: count }
      end
      grouped.values
    end

    def price_facet(context)
      row = context.reorder(nil).pick(Arel.sql("MIN(price_cents), MAX(price_cents)"))
      { min: (row&.first.to_i) / 100.0, max: (row&.last.to_i) / 100.0 }
    end

    def availability_facet(ids)
      Product.where(id: ids).where(id: in_stock_product_ids).count
    end
  end
end
