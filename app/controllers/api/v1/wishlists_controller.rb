# frozen_string_literal: true

module Api
  module V1
    # Storefront wishlist. Signed-in customers only (unlike the guest-capable
    # cart) — saving for later is tied to the account.
    class WishlistsController < BaseController
      include CustomerAuthentication

      before_action :authenticate_customer!

      # GET /api/v1/wishlist — paginated (page/per_page) for the wishlist page's
      # infinite scroll; a wishlist can grow large over time.
      def show
        items, meta = paginate(wishlist_items)
        render_success(WishlistItemSerializer.collection(items), meta: meta)
      end

      # GET /api/v1/wishlist/product_ids — every wishlisted product id,
      # unpaginated. Cheap even for a large wishlist (just integers) and lets
      # the heart-toggle state on product cards/PDP know full membership
      # without loading every wishlist item's full product payload.
      def product_ids
        render_success(current_customer.wishlist_items.pluck(:product_id))
      end

      # POST /api/v1/wishlist/items  { product_id }
      def add_item
        product = Product.kept.find(params.require(:product_id))
        item = current_customer.wishlist_items.find_or_create_by!(product: product)
        render_success(WishlistItemSerializer.new(item).as_json, status: :created)
      end

      # DELETE /api/v1/wishlist/items/:product_id
      def remove_item
        item = current_customer.wishlist_items.find_by!(product_id: params[:product_id])
        item.destroy!
        render_success({ product_id: item.product_id })
      end

      private

      def wishlist_items
        current_customer.wishlist_items.includes(product: [ :brand, :product_images ]).order(:id)
      end
    end
  end
end
