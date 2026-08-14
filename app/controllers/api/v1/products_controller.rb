# frozen_string_literal: true

module Api
  module V1
    class ProductsController < BaseController
      # GET /api/v1/products — live products, filterable + paginated. A
      # product with real color/size options renders as one card per color
      # (its primary variant attribute), not one card for the whole product.
      def index
        result = Products::Search.new(Product.kept.live, params).call
        products, meta = paginate(result.records)
        render_success(listing_items(products, result.selected_attributes), meta: meta.merge(facets: result.facets))
      end

      # GET /api/v1/products/:slug
      def show
        product = Product.kept.live
                         .includes(
                           :brand, :category, :tax_class, :specifications,
                           { product_images: { attribute_value: :product_attribute } },
                           { variants: [ :inventory_item, { variant_option_values: { attribute_value: :product_attribute } } ] },
                           { product_relations: :related_product }
                         )
                         .find_by!(slug: params[:id])
        render_success(ProductDetailSerializer.new(product).as_json)
      end

      private

      # One serialized card per color group; products with no real options
      # (or none matching a category-linked attribute) fall back to a single
      # card from their own cheapest sellable variant. When a group's own
      # attribute is actively filtered on (e.g. attr[color]=black matched
      # this product via one of its other variants), only the selected
      # value(s) render — otherwise picking "Black" would still show that
      # product's White card too.
      def listing_items(products, selected_attributes)
        groups = Products::VariantGroups.for(products)
        products.flat_map do |product|
          entries = groups[product.id]
          next [ ProductListSerializer.new(product).as_json ] if entries.blank?

          entries = filter_to_selected(entries, selected_attributes)
          entries.map { |entry| ProductListSerializer.new(product, variant: entry.variant, group_value: entry.value).as_json }
        end
      end

      def filter_to_selected(entries, selected_attributes)
        return entries if selected_attributes.blank?

        codes = selected_attributes[entries.first.value.product_attribute.code]
        return entries if codes.blank?

        matching = entries.select { |entry| codes.include?(entry.value.code) }
        matching.presence || entries
      end
    end
  end
end
