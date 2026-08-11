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
        render_success(listing_items(products), meta: meta.merge(facets: result.facets))
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
      # card from their own cheapest sellable variant.
      def listing_items(products)
        groups = Products::VariantGroups.for(products)
        products.flat_map do |product|
          entries = groups[product.id]
          next [ ProductListSerializer.new(product).as_json ] if entries.blank?

          entries.map { |entry| ProductListSerializer.new(product, variant: entry.variant, group_value: entry.value).as_json }
        end
      end
    end
  end
end
