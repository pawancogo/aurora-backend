# frozen_string_literal: true

# A line on an order — a full snapshot of the cart item at placement time
# (name/sku/options/price), so later catalog changes never alter a past
# order. product_variant is kept for convenience/analytics only.
class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :product_variant, optional: true

  validates :product_name, :variant_sku, presence: true
  validates :quantity, numericality: { only_integer: true, greater_than: 0 }
  validates :unit_price_cents, :line_total_cents, numericality: { greater_than_or_equal_to: 0 }

  def unit_price
    unit_price_cents / 100.0
  end

  def line_total
    line_total_cents / 100.0
  end
end
