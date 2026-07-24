# frozen_string_literal: true

module Api
  module V1
    class ProductsController < BaseController
      # GET /api/v1/products — live products, filterable + paginated.
      def index
        relation = Products::Query.new(Product.kept.live, params).call
        products, meta = paginate(relation)
        render_success(products.map { |product| ProductListSerializer.new(product).as_json }, meta: meta)
      end

      # GET /api/v1/products/:slug
      def show
        product = Product.kept.live
                         .includes(:brand, :category, :tax_class, :product_images)
                         .find_by!(slug: params[:id])
        render_success(ProductDetailSerializer.new(product).as_json)
      end
    end
  end
end
