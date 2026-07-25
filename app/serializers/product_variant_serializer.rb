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
      discount_percent: discount_percent,
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

  private

  def discount_percent
    mrp = @variant.mrp_cents_effective
    price = @variant.price_cents_effective
    return 0 if mrp.zero? || mrp <= price

    (((mrp - price).to_f / mrp) * 100).round
  end
end
