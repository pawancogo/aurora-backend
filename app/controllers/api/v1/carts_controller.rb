# frozen_string_literal: true

module Api
  module V1
    # Storefront cart. Works for guests (identified by the X-Cart-Token header,
    # echoed back in the response) and for the signed-in customer. Line prices
    # and stock are validated live by Carts::Manager.
    class CartsController < BaseController
      include CustomerAuthentication

      rescue_from Carts::Manager::Error do |error|
        render_error(code: "cart_error", message: error.message, status: :unprocessable_content)
      end

      # GET /api/v1/cart
      def show
        render_cart(current_cart)
      end

      # POST /api/v1/cart/items  { variant_id, quantity }
      def add_item
        variant = ProductVariant.find(params.require(:variant_id))
        cart = current_cart(create: true)
        Carts::Manager.new(cart).add(variant, params.fetch(:quantity, 1))
        render_cart(cart, status: :created)
      end

      # PATCH /api/v1/cart/items/:id  { quantity }
      def update_item
        cart = current_cart or raise ActiveRecord::RecordNotFound
        item = cart.cart_items.find(params[:id])
        Carts::Manager.new(cart).update(item, params.require(:quantity))
        render_cart(cart)
      end

      # DELETE /api/v1/cart/items/:id
      def remove_item
        cart = current_cart or raise ActiveRecord::RecordNotFound
        item = cart.cart_items.find(params[:id])
        Carts::Manager.new(cart).remove(item)
        render_cart(cart)
      end

      private

      EMPTY_CART = { id: nil, token: nil, item_count: 0, subtotal: 0.0, currency: "INR", items: [] }.freeze

      # Items paginate (page/per_page) so a cart with many lines doesn't ship
      # everything in one response; item_count/subtotal always reflect the
      # whole cart regardless of which page of items is returned.
      def render_cart(cart, status: :ok)
        unless cart
          render_success(EMPTY_CART, status: status)
          return
        end

        items, meta = paginate(cart.items)
        render_success(CartSerializer.new(cart, items: items).as_json, meta: meta, status: status)
      end

      # The current cart: the customer's when signed in, else the guest cart
      # named by X-Cart-Token. `create:` makes one when none exists yet.
      def current_cart(create: false)
        if current_customer
          create ? Cart.find_or_create_by!(customer: current_customer) : Cart.find_by(customer: current_customer)
        else
          token = request.headers["X-Cart-Token"].presence
          # customer_id: nil guards against a stale token (e.g. kept client-side
          # after logout) resolving to a since-claimed customer cart.
          (token && Cart.find_by(token: token, customer_id: nil)) || (create ? Cart.create! : nil)
        end
      end
    end
  end
end
