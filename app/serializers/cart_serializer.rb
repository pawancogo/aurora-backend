# frozen_string_literal: true

# The cart for the storefront: token (so guests can re-identify their cart),
# totals, and line items.
class CartSerializer
  def initialize(cart)
    @cart = cart
  end

  def as_json(*)
    items = @cart.items.to_a
    {
      id: @cart.id,
      token: @cart.token,
      item_count: items.sum(&:quantity),
      subtotal: items.sum(&:line_total_cents) / 100.0,
      currency: items.first&.product_variant&.product&.currency || "INR",
      items: items.map { |item| CartItemSerializer.new(item).as_json }
    }
  end
end
