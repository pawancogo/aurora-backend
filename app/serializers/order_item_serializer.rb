# frozen_string_literal: true

# A snapshotted order line — product name/sku/options/price as they were at
# placement time, independent of later catalog changes.
class OrderItemSerializer
  def initialize(item)
    @item = item
  end

  def as_json(*)
    {
      id: @item.id,
      product_name: @item.product_name,
      variant_sku: @item.variant_sku,
      options: @item.options_snapshot,
      unit_price: @item.unit_price,
      quantity: @item.quantity,
      line_total: @item.line_total
    }
  end
end
