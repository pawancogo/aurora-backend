# frozen_string_literal: true

# A purchasable variant for the storefront: effective price/stock + its option
# combination (e.g. [{attribute: "Color", value: "Red"}]).
class ProductVariantSerializer
  def initialize(variant)
    @variant = variant
  end

  def as_json(*)
    {
      id: @variant.id,
      sku: @variant.sku,
      price: @variant.price,
      mrp: @variant.mrp,
      discount_percent: @variant.discount_percent,
      available: @variant.available,
      in_stock: @variant.in_stock?,
      options: @variant.attribute_values.map do |value|
        {
          attribute: value.product_attribute&.name,
          attribute_code: value.product_attribute&.code,
          value: value.value,
          value_code: value.code
        }
      end
    }
  end
end
