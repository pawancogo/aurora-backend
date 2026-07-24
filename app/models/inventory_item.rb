# frozen_string_literal: true

# Stock for a single variant. `available = on_hand - reserved`; a sale draws down
# on_hand, a reservation moves quantity into `reserved` (see Inventory services).
class InventoryItem < ApplicationRecord
  has_paper_trail

  belongs_to :product_variant
  has_many :stock_movements, -> { order(created_at: :desc, id: :desc) }, dependent: :destroy

  validates :on_hand, :reserved, :low_stock_threshold,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  # Items at/under their threshold (0 threshold = alerts disabled).
  scope :low_stock, lambda {
    where("low_stock_threshold > 0 AND (on_hand - reserved) <= low_stock_threshold")
  }
  scope :out_of_stock, -> { where("(on_hand - reserved) <= 0") }

  def available
    on_hand - reserved
  end

  def in_stock?
    available.positive? || backorderable?
  end

  def low_stock?
    low_stock_threshold.positive? && available <= low_stock_threshold
  end
end
