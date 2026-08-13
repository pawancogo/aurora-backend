# frozen_string_literal: true

# Compact product representation for listing pages (PLP). A product with real
# option variants can be split into several storefront listing cards — one per
# distinct value of its primary variant attribute (e.g. Color) — by passing
# the group's representative `variant:`/`group_value:` explicitly; other
# callers (wishlist, homepage sections, admin) get the single cheapest-variant
# card by leaving them unset.
class ProductListSerializer
  def initialize(product, variant: nil, group_value: nil)
    @product = product
    @variant = variant
    @group_value = group_value
  end

  def as_json(*)
    {
      id: @product.id,
      name: variant.display_name,
      slug: @product.slug,
      sku: @product.sku,
      variant_id: variant.id,
      price: variant.price,
      mrp: variant.mrp,
      currency: @product.currency,
      discount_percent: variant.discount_percent,
      brand: @product.brand&.name,
      category_slug: @product.category&.slug,
      featured: @product.featured,
      new_arrival: @product.new_arrival,
      best_seller: @product.best_seller,
      image: variant.display_image_url,
      group: group_json
    }
  end

  private

  def variant
    @variant ||= @product.sellable_variants.min_by(&:price_cents) || @product.master_variant
  end

  def group_json
    return nil unless @group_value

    attribute = @group_value.product_attribute
    { attribute: attribute.name, attribute_code: attribute.code, value: @group_value.value, value_code: @group_value.code }
  end
end
