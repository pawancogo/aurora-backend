# frozen_string_literal: true

# Immutable ledger entry for an inventory change. Created only through the
# Inventory services (never edited), so the sum of movements reconciles stock.
class StockMovement < ApplicationRecord
  belongs_to :inventory_item
  belongs_to :admin_user, optional: true

  # on-hand reasons move `on_hand`; reservation/release move `reserved`.
  enum :reason, {
    restock: 0,      # stock received
    sale: 1,         # sold / fulfilled (negative)
    adjustment: 2,   # manual correction (±)
    return: 3,       # customer return back to stock (positive)
    reservation: 4,  # held for a cart/order (moves into reserved)
    release: 5       # reservation freed (moves out of reserved)
  }, prefix: :reason

  validates :quantity, numericality: { only_integer: true, other_than: 0 }

  # created_at is set explicitly (table has no updated_at); default to now.
  before_validation { self.created_at ||= Time.current }
  validates :created_at, presence: true

  scope :recent, -> { order(created_at: :desc, id: :desc) }
end
