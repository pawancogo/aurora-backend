# frozen_string_literal: true

module Admin
  # Manages a product's variants (option combinations, price, SKU, initial stock).
  class ProductVariantsController < BaseController
    before_action -> { require_permission!("products.read") }, only: :index
    before_action -> { require_permission!("products.manage") }, only: %i[new create edit update destroy]
    before_action :set_product
    before_action :set_variant, only: %i[edit update destroy]
    before_action :load_attributes, only: %i[new create edit update]

    def index
      @variants = @product.variants.non_master
                          .includes(:inventory_item, attribute_values: :product_attribute).ordered
    end

    def new
      @variant = @product.variants.build(active: true)
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

    # Only attributes that actually have values are pickable.
    def load_attributes
      @attributes = ProductAttribute.includes(:attribute_values).ordered
                                    .select { |attribute| attribute.attribute_values.any? }
    end

    def variant_params
      raw = params.require(:product_variant)
      permitted = raw.permit(:sku, :barcode, :active)
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
