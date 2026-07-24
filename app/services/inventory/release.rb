# frozen_string_literal: true

module Inventory
  # Frees a previously held reservation, moving quantity back out of `reserved`.
  # Never releases more than is currently reserved.
  class Release
    def initialize(inventory_item:, quantity:, actor: nil, note: nil)
      @item = inventory_item
      @quantity = quantity.to_i
      @actor = actor
      @note = note
    end

    # Returns the created StockMovement (nil if there was nothing to release).
    def call
      raise Error, "Quantity must be positive" unless @quantity.positive?

      releasable = [ @quantity, @item.reserved ].min
      return nil if releasable.zero?

      @item.transaction do
        @item.update!(reserved: @item.reserved - releasable)
        @item.stock_movements.create!(
          quantity: -releasable, reason: :release, admin_user: @actor, note: @note
        )
      end
    end
  end
end
