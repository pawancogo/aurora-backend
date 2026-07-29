# frozen_string_literal: true

# A line in a cart: a variant + quantity. Price is derived from the variant at
# read time (never snapshotted) so the cart reflects current pricing.
class CartItem < ApplicationRecord
  belongs_to :cart
  belongs_to :product_variant

  validates :quantity, numericality: { only_integer: true, greater_than: 0 }
  validates :product_variant_id, uniqueness: { scope: :cart_id }

  def unit_price_cents
    product_variant.price_cents_effective
  end

  def line_total_cents
    unit_price_cents * quantity
  end
end
