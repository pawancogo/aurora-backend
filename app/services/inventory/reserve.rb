# frozen_string_literal: true

module Inventory
  # Holds stock for a pending cart/order by moving quantity into `reserved`
  # (on-hand is untouched until fulfilment). Guards against overselling unless the
  # item is backorderable. Foundation for cart/checkout — TTL expiry lands with
  # those sprints.
  class Reserve
    def initialize(inventory_item:, quantity:, actor: nil, note: nil)
      @item = inventory_item
      @quantity = quantity.to_i
      @actor = actor
      @note = note
    end

    # Returns the created StockMovement.
    def call
      raise Error, "Quantity must be positive" unless @quantity.positive?

      unless @item.backorderable? || @item.available >= @quantity
        raise Error, "Insufficient stock to reserve (#{@item.available} available)"
      end

      @item.transaction do
        @item.update!(reserved: @item.reserved + @quantity)
        @item.stock_movements.create!(
          quantity: @quantity, reason: :reservation, admin_user: @actor, note: @note
        )
      end
    end
  end
end
