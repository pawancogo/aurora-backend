# frozen_string_literal: true

module Admin
  # Inventory operations: stock levels across purchasable variants, low-stock
  # filtering, per-variant adjustments (through the ledger), and movement history.
  class InventoryController < BaseController
    before_action -> { require_permission!("inventory.read") }, only: %i[index show]
    before_action -> { require_permission!("inventory.manage") }, only: %i[adjust update_settings]
    before_action :set_variant, only: %i[show adjust update_settings]

    def index
      @variants = filtered_scope.page(params[:page]).per(helpers.current_per_page)
      @low_stock_count = base_scope.where(low_stock_sql).count
    end

    def show
      @item = @variant.inventory_item
      @movements = @item.stock_movements.recent.includes(:admin_user).page(params[:page]).per(20)
    end

    # Apply a signed delta (mode: add) or set an absolute on-hand (mode: set).
    def adjust
      item = @variant.inventory_item
      quantity = params[:quantity].to_i
      delta = params[:mode] == "set" ? (quantity - item.on_hand) : quantity

      if delta.zero?
        return redirect_to admin_inventory_item_path(@variant), notice: "No change to stock."
      end

      reason = params[:mode] == "set" ? "adjustment" : params[:reason].presence || "adjustment"
      Inventory::AdjustStock.new(
        inventory_item: item, quantity: delta, reason: reason,
        actor: current_admin_user, note: params[:note].presence
      ).call
      redirect_to admin_inventory_item_path(@variant), notice: "Stock updated."
    rescue Inventory::Error => e
      redirect_to admin_inventory_item_path(@variant), alert: e.message
    end

    # Update thresholds/backorder policy (not a stock change → no ledger entry).
    def update_settings
      @variant.inventory_item.update(
        low_stock_threshold: params.dig(:inventory_item, :low_stock_threshold),
        backorderable: params.dig(:inventory_item, :backorderable)
      )
      redirect_to admin_inventory_item_path(@variant), notice: "Inventory settings saved."
    end

    private

    def set_variant
      @variant = ProductVariant.includes(:product, :inventory_item, attribute_values: :product_attribute)
                               .find(params[:variant_id])
    end

    def base_scope
      ProductVariant.purchasable
                    .joins(:product).left_joins(:inventory_item)
                    .where(products: { deleted_at: nil })
    end

    def filtered_scope
      scope = base_scope
              .includes(:inventory_item, :product, attribute_values: :product_attribute)
              .order(Arel.sql("products.name ASC, product_variants.position ASC, product_variants.id ASC"))

      if params[:q].present?
        term = "%#{ProductVariant.sanitize_sql_like(params[:q].to_s.strip)}%"
        scope = scope.where("products.name ILIKE :t OR product_variants.sku ILIKE :t", t: term)
      end

      scope = scope.where(low_stock_sql) if params[:low_stock].present?
      scope
    end

    def low_stock_sql
      "inventory_items.low_stock_threshold > 0 AND " \
        "(inventory_items.on_hand - inventory_items.reserved) <= inventory_items.low_stock_threshold"
    end
  end
end
