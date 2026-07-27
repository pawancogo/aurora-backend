# frozen_string_literal: true

module Admin
  # Catalog-wide list of every product variant (real, non-master), so variants
  # are browsable/searchable without drilling into each product. Edit jumps to
  # the per-product variant form; stock is managed under Inventory.
  class VariantsController < BaseController
    before_action -> { require_permission!("products.read") }, only: :index

    def index
      scope = ProductVariant.non_master
                            .joins(:product).left_joins(:inventory_item)
                            .includes(:product, :inventory_item, attribute_values: :product_attribute)
                            .where(products: { deleted_at: nil })
                            .order(Arel.sql("products.name ASC, product_variants.position ASC, product_variants.id ASC"))

      if params[:q].present?
        term = "%#{ProductVariant.sanitize_sql_like(params[:q].to_s.strip)}%"
        scope = scope.where("products.name ILIKE :t OR product_variants.sku ILIKE :t", t: term)
      end

      @variants = scope.page(params[:page]).per(helpers.current_per_page)
    end
  end
end
