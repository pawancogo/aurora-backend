# frozen_string_literal: true

# The cart for the storefront: token (so guests can re-identify their cart),
# totals, and line items. `items:` lets the controller pass a paginated page
# of items while `item_count`/`subtotal` still reflect the whole cart (they
# come from the Cart model's own full-table aggregates, not the passed page).
class CartSerializer
  def initialize(cart, items: nil)
    @cart = cart
    @items = items || cart.items.to_a
  end

  def as_json(*)
    {
      id: @cart.id,
      token: @cart.token,
      item_count: @cart.item_count,
      subtotal: @cart.subtotal_cents / 100.0,
      currency: @items.first&.product_variant&.product&.currency || "INR",
      items: @items.map { |item| CartItemSerializer.new(item).as_json }
    }
  end
end
