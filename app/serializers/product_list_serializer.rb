# frozen_string_literal: true

# Compact product representation for listing pages (PLP).
class ProductListSerializer
  def initialize(product)
    @product = product
  end

  def as_json(*)
    {
      id: @product.id,
      name: @product.name,
      slug: @product.slug,
      sku: @product.sku,
      price: @product.price,
      mrp: @product.mrp,
      currency: @product.currency,
      discount_percent: @product.discount_percent,
      brand: @product.brand&.name,
      category_slug: @product.category&.slug,
      featured: @product.featured,
      new_arrival: @product.new_arrival,
      best_seller: @product.best_seller,
      image: @product.primary_image&.source_url
    }
  end
end
