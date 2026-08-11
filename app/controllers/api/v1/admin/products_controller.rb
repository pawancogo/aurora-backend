# frozen_string_literal: true

module Api
  module V1
    module Admin
      class ProductsController < Api::V1::BaseController
        include AdminAuthentication

        before_action -> { authorize_permission!("products.read") }, only: %i[index show]
        before_action -> { authorize_permission!("products.manage") }, only: %i[create update destroy]

        # Admins see every status (draft/active/archived). Generic search + facet filters.
        def index
          result = Product.search(params, scope: Product.kept.includes(:brand, :category).order(created_at: :desc),
                                          paginate: false)
          products, meta = paginate(result.records)
          render_success(
            products.map { |product| ProductListSerializer.new(product).as_json },
            meta: meta.merge(facets: result.facets)
          )
        end

        def show
          product = Product.kept.includes(:brand, :category, :tax_class, :product_images).find(params[:id])
          render_success(ProductDetailSerializer.new(product).as_json)
        end

        def create
          product = Product.new(product_params)
          product.save!
          apply_master_variant_price(product)
          render_success(ProductDetailSerializer.new(product).as_json, status: :created)
        end

        def update
          product = Product.kept.find(params[:id])
          product.update!(product_params)
          apply_master_variant_price(product)
          render_success(ProductDetailSerializer.new(product).as_json)
        end

        def destroy
          Product.kept.find(params[:id]).discard!
          render_success({ message: "Product archived." })
        end

        private

        def product_params
          params.require(:product).permit(
            :name, :slug, :sku, :brand_id, :category_id, :tax_class_id, :description,
            :status, :featured, :new_arrival, :best_seller,
            :currency, :weight_grams, :warranty,
            :meta_title, :meta_description, :search_keywords, :published_at,
            highlights: [],
            dimensions: {},
            product_images_attributes: %i[id source_url alt_text position primary _destroy]
          )
        end

        # A product is never itself sellable — price/MRP set here land on the
        # master variant, which is the sellable unit for a product with no
        # real option variants.
        def apply_master_variant_price(product)
          raw = params.require(:product)
          return unless raw.key?(:price_cents) || raw.key?(:mrp_cents)

          attrs = {}
          attrs[:price_cents] = raw[:price_cents] if raw.key?(:price_cents)
          attrs[:mrp_cents] = raw[:mrp_cents] if raw.key?(:mrp_cents)
          product.master_variant.update!(attrs)
        end
      end
    end
  end
end
