# frozen_string_literal: true

module Admin
  # Manages a product's variants (option combinations, price, SKU, initial stock).
  class ProductVariantsController < BaseController
    before_action -> { require_permission!("products.read") }, only: :index
    before_action -> { require_permission!("products.manage") }, only: %i[new create edit update destroy]
    before_action :set_product
    before_action :set_variant, only: %i[edit update destroy]
    before_action :load_attributes, only: %i[new create edit update]
    before_action :load_copy_sources, only: %i[new create]

    def index
      @variants = @product.variants.non_master
                          .includes(:inventory_item, attribute_values: :product_attribute).ordered
    end

    def new
      @variant = @product.variants.build(active: true)
      @copy_source = copy_price_and_status_from(@variant, copy_from_param)
      @copy_requested = copy_from_param.present?
    end

    def create
      @variant = @product.variants.build(variant_params)
      assign_option_values(@variant)
      if option_values_present? && @variant.save
        apply_initial_stock(@variant)
        redirect_to admin_product_variants_path(@product), notice: "Variant created."
      else
        @variant.errors.add(:base, "Pick at least one option value") unless option_values_present?
        render :new, status: :unprocessable_content
      end
    end

    def edit; end

    def update
      @variant.assign_attributes(variant_params)
      assign_option_values(@variant)
      if option_values_present? && @variant.save
        redirect_to admin_product_variants_path(@product), notice: "Variant updated."
      else
        @variant.errors.add(:base, "Pick at least one option value") unless option_values_present?
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      @variant.destroy
      redirect_to admin_product_variants_path(@product), notice: "Variant removed."
    end

    private

    def set_product
      @product = Product.kept.find(params[:product_id])
    end

    def set_variant
      @variant = @product.variants.non_master
                         .includes(:variant_option_values).find(params[:id])
    end

    # Attributes offered for this product: scoped to its category (with values),
    # falling back to all when the category has no attribute links configured.
    def load_attributes
      @attributes = @product.applicable_attributes
    end

    def load_copy_sources
      @copy_sources = @product.variants.non_master.ordered
    end

    def variant_params
      raw = params.require(:product_variant)
      permitted = raw.permit(:name, :image_url, :sku, :barcode, :active)
      permitted[:price_cents] = to_cents(raw[:price]) if raw[:price].present?
      permitted[:mrp_cents]   = to_cents(raw[:mrp])   if raw[:mrp].present?
      permitted
    end

    def to_cents(value)
      (value.to_f * 100).round
    end

    # Rebuild option values from the { attribute_id => value_id } select map.
    def assign_option_values(variant)
      variant.variant_option_values.destroy_all if variant.persisted?
      selected_value_ids.each { |value_id| variant.variant_option_values.build(attribute_value_id: value_id) }
    end

    def selected_value_ids
      return @selected_value_ids if defined?(@selected_value_ids)

      raw = params[:option_values]
      ids = []
      raw.each_value { |value| ids << value.to_i if value.present? } if raw.respond_to?(:each_value)
      @selected_value_ids = AttributeValue.where(id: ids).pluck(:id)
    end

    def option_values_present?
      selected_value_ids.any?
    end

    # The typed-in id wins over the dropdown when both are filled in — typing
    # an id is a deliberate choice, the dropdown's value is often just left
    # over from a previous load.
    def copy_from_param
      params[:copy_from_id].presence || params[:copy_from_select].presence
    end

    # Prefills price/MRP/active from an existing variant of this product, so
    # building out a full option matrix (e.g. one size per color) doesn't mean
    # retyping the same price on every row. Options and SKU are never copied —
    # picking a new combination and getting a fresh SKU is the whole point.
    # Returns the source variant (for the "prefilled from #X" banner) or nil.
    def copy_price_and_status_from(variant, source_id)
      return nil if source_id.blank?

      source = @product.variants.non_master.find_by(id: source_id)
      return nil unless source

      variant.price_cents = source.price_cents
      variant.mrp_cents = source.mrp_cents
      variant.active = source.active
      source
    end

    def apply_initial_stock(variant)
      quantity = params[:initial_stock].to_i
      return unless quantity.positive?

      Inventory::AdjustStock.new(
        inventory_item: variant.inventory_item, quantity: quantity,
        reason: "restock", actor: current_admin_user, note: "Initial stock"
      ).call
    end
  end
end
