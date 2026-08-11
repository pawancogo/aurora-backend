# frozen_string_literal: true

module Products
  # For a batch of products that vary by a primary attribute (e.g. Color),
  # finds the cheapest active variant per (product, attribute value) — the
  # listing splits a multi-option product into one card per such group.
  # Products with no primary_variant_attribute are simply absent from the
  # result; the caller falls back to their single sellable variant.
  #
  #   Products::VariantGroups.for(products) # => { product_id => [Group, ...] }
  class VariantGroups
    Group = Struct.new(:variant, :value, keyword_init: true)

    def self.for(products)
      new(products).call
    end

    def initialize(products)
      @products_by_attribute = products.select(&:primary_variant_attribute).group_by(&:primary_variant_attribute)
    end

    def call
      @products_by_attribute.each_with_object({}) do |(attribute, products), result|
        rows = rows_for(attribute, products).to_a
        next if rows.empty?

        variants = ProductVariant.where(id: rows.map(&:pv_id)).includes(:inventory_item).index_by(&:id)
        values = AttributeValue.where(id: rows.map(&:value_id)).includes(:product_attribute).index_by(&:id)

        rows.group_by(&:product_id).each do |product_id, product_rows|
          result[product_id] = product_rows.map do |row|
            Group.new(variant: variants.fetch(row.pv_id), value: values.fetch(row.value_id))
          end
        end
      end
    end

    private

    # Cheapest active variant per (product, attribute value), scoped to one
    # attribute at a time so a product with two option attributes (e.g. Jeans'
    # Color + Waist) is only ever grouped by its own primary one.
    def rows_for(attribute, products)
      ProductVariant
        .select("DISTINCT ON (product_variants.product_id, attribute_values.id)
                 product_variants.id AS pv_id, product_variants.product_id AS product_id,
                 attribute_values.id AS value_id")
        .joins(variant_option_values: :attribute_value)
        .where(is_master: false, active: true, product_id: products.map(&:id))
        .where(attribute_values: { product_attribute_id: attribute.id })
        .order("product_variants.product_id, attribute_values.id, product_variants.price_cents ASC, product_variants.id ASC")
    end
  end
end
