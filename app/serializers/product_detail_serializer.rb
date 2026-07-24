# frozen_string_literal: true

# Full product representation for the detail page (PDP).
class ProductDetailSerializer
  def initialize(product)
    @product = product
  end

  def as_json(*)
    {
      id: @product.id,
      name: @product.name,
      slug: @product.slug,
      sku: @product.sku,
      description: @product.description,
      highlights: @product.highlights,
      price: @product.price,
      mrp: @product.mrp,
      currency: @product.currency,
      discount_percent: @product.discount_percent,
      status: @product.status,
      featured: @product.featured,
      new_arrival: @product.new_arrival,
      best_seller: @product.best_seller,
      weight_grams: @product.weight_grams,
      dimensions: @product.dimensions,
      warranty: @product.warranty,
      brand: brand_json,
      category: category_json,
      tax: tax_json,
      images: @product.product_images.map { |image| ProductImageSerializer.new(image).as_json },
      meta_title: @product.meta_title,
      meta_description: @product.meta_description,
      search_keywords: @product.search_keywords,
      created_at: @product.created_at
    }
  end

  private

  def brand_json
    return nil unless @product.brand

    { id: @product.brand.id, name: @product.brand.name, slug: @product.brand.slug }
  end

  def category_json
    return nil unless @product.category

    { id: @product.category.id, name: @product.category.name, slug: @product.category.slug }
  end

  def tax_json
    return nil unless @product.tax_class

    { rate: @product.tax_class.rate.to_f, hsn_code: @product.tax_class.hsn_code }
  end
end
