# frozen_string_literal: true

# A cart line for the storefront: the product/variant, live price, quantity, and
# current availability (so the UI can flag stock changes).
class CartItemSerializer
  def initialize(item)
    @item = item
    @variant = item.product_variant
    @product = @variant.product
  end

  def as_json(*)
    {
      id: @item.id,
      variant_id: @variant.id,
      sku: @variant.sku,
      product: {
        id: @product.id,
        name: @product.name,
        slug: @product.slug,
        image: @product.primary_image&.source_url
      },
      options: @variant.attribute_values.map do |value|
        { attribute: value.product_attribute&.name, value: value.value }
      end,
      unit_price: @item.unit_price_cents / 100.0,
      quantity: @item.quantity,
      line_total: @item.line_total_cents / 100.0,
      currency: @product.currency,
      available: @variant.available,
      in_stock: @variant.in_stock?
    }
  end
end
