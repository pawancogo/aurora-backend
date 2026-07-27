# frozen_string_literal: true

module Admin
  # Catalog-wide list of every product variant (real, non-master), so variants
  # are browsable/searchable/filterable without drilling into each product.
  # Edit jumps to the per-product variant form; stock is managed under Inventory.
  class VariantsController < BaseController
    before_action -> { require_permission!("products.read") }, only: :index

    def index
      scope = filtered_scope.order(
        Arel.sql("products.name ASC, product_variants.position ASC, product_variants.id ASC")
      )
      @variants = scope.page(params[:page]).per(helpers.current_per_page)

      # Filter dropdown sources
      @brands = Brand.order(:name).pluck(:name, :id)
      @categories = Category.kept.order(:name).pluck(:name, :id)
      @filter_attributes = ProductAttribute.ordered.includes(:attribute_values)
                                           .select { |attribute| attribute.attribute_values.any? }
    end

    private

    def base_scope
      ProductVariant.non_master
                    .joins(:product).left_joins(:inventory_item)
                    .includes(:product, :inventory_item, attribute_values: :product_attribute)
                    .where(products: { deleted_at: nil })
    end

    def filtered_scope
      scope = base_scope
      scope = apply_search(scope)
      scope = apply_associations(scope)
      scope = apply_stock(scope)
      apply_options(scope)
    end

    def apply_search(scope)
      return scope if params[:q].blank?

      term = "%#{ProductVariant.sanitize_sql_like(params[:q].to_s.strip)}%"
      scope.where("products.name ILIKE :t OR product_variants.sku ILIKE :t", t: term)
    end

    def apply_associations(scope)
      scope = scope.where(products: { brand_id: params[:brand_id] }) if params[:brand_id].present?
      scope = scope.where(products: { category_id: params[:category_id] }) if params[:category_id].present?
      scope = scope.where(product_variants: { active: params[:active] == "1" }) if params[:active].present?
      scope
    end

    def apply_stock(scope)
      available = "(inventory_items.on_hand - inventory_items.reserved)"
      case params[:stock]
      when "in"  then scope.where("#{available} > 0")
      when "out" then scope.where("#{available} <= 0")
      when "low" then scope.where("inventory_items.low_stock_threshold > 0 AND #{available} <= inventory_items.low_stock_threshold")
      else scope
      end
    end

    # params[:opt] = { attribute_id => attribute_value_id }; each narrows to variants
    # carrying that value (multiple options combine with AND).
    def apply_options(scope)
      return scope unless params[:opt].respond_to?(:each_value)

      params[:opt].each_value do |value_id|
        next if value_id.blank?

        scope = scope.where(id: VariantOptionValue.where(attribute_value_id: value_id).select(:product_variant_id))
      end
      scope
    end
  end
end
