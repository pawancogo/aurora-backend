# frozen_string_literal: true

module Api
  module V1
    # Storefront wishlist. Signed-in customers only (unlike the guest-capable
    # cart) — saving for later is tied to the account.
    class WishlistsController < BaseController
      include CustomerAuthentication

      before_action :authenticate_customer!

      # GET /api/v1/wishlist
      def show
        render_success(WishlistItemSerializer.collection(wishlist_items))
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
        render_success(WishlistItemSerializer.collection(wishlist_items))
      end

      private

      def wishlist_items
        current_customer.wishlist_items.includes(product: [ :brand, :product_images ]).order(:id)
      end
    end
  end
end
