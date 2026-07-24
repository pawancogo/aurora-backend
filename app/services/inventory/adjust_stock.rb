# frozen_string_literal: true

module Inventory
  # Applies a signed delta to an item's on-hand quantity and records a ledger
  # movement, atomically. Use for received stock, manual corrections, sales, and
  # returns — anything that changes physical on-hand (not reservations).
  class AdjustStock
    ON_HAND_REASONS = %w[restock sale adjustment return].freeze

    def initialize(inventory_item:, quantity:, reason:, actor: nil, note: nil)
      @item = inventory_item
      @quantity = quantity.to_i
      @reason = reason.to_s
      @actor = actor
      @note = note
    end

    # Returns the created StockMovement.
    def call
      raise Error, "Quantity must be non-zero" if @quantity.zero?
      raise Error, "Unknown on-hand reason: #{@reason}" unless ON_HAND_REASONS.include?(@reason)

      new_on_hand = @item.on_hand + @quantity
      raise Error, "Insufficient stock (on-hand would go negative)" if new_on_hand.negative?

      @item.transaction do
        @item.update!(on_hand: new_on_hand)
        @item.stock_movements.create!(
          quantity: @quantity, reason: @reason, admin_user: @actor, note: @note
        )
      end
    end
  end
end
