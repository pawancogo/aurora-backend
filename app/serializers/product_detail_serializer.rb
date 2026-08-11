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
      price: @product.display_price,
      mrp: @product.display_mrp,
      currency: @product.currency,
      discount_percent: @product.display_discount_percent,
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
      in_stock: @product.in_stock?,
      total_available: @product.total_available,
      price_range: price_range_json,
      has_variants: @product.has_variants?,
      options: options_json,
      variants: sellable_variants.map { |variant| ProductVariantSerializer.new(variant).as_json },
      specifications: @product.specifications.map { |spec| { name: spec.name, value: spec.value, group: spec.spec_group } },
      related_products: related_json,
      meta_title: @product.meta_title,
      meta_description: @product.meta_description,
      search_keywords: @product.search_keywords,
      created_at: @product.created_at
    }
  end

  private

  def sellable_variants
    @sellable_variants ||= @product.sellable_variants.to_a
  end

  # Min/max effective price across sellable variants — drives "from ₹X" display.
  def price_range_json
    prices = sellable_variants.map(&:price_cents_effective)
    return { min: @product.display_price, max: @product.display_price } if prices.empty?

    { min: prices.min / 100.0, max: prices.max / 100.0 }
  end

  # Selector structure: each variant-defining attribute + the values actually
  # offered by this product's sellable variants (registry order).
  def options_json
    return [] unless @product.has_variants?

    values_by_attribute = sellable_variants.flat_map(&:attribute_values).uniq.group_by(&:product_attribute_id)
    @product.option_attributes.map do |attribute|
      values = (values_by_attribute[attribute.id] || []).sort_by { |value| [ value.position, value.id ] }
      {
        id: attribute.id, name: attribute.name, code: attribute.code,
        values: values.map { |value| { id: value.id, value: value.value, code: value.code, metadata: value.metadata } }
      }
    end
  end

  def related_json
    @product.product_relations.ordered.filter_map do |relation|
      related = relation.related_product
      next unless related&.kept? && related.active?

      {
        kind: relation.relation_kind,
        id: related.id, name: related.name, slug: related.slug,
        price: related.display_price, mrp: related.display_mrp, discount_percent: related.display_discount_percent,
        image: related.primary_image&.source_url
      }
    end
  end

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
