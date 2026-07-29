# frozen_string_literal: true

module Carts
  # Mutates a cart with inventory + availability validation.
  #
  #   Carts::Manager.new(cart).add(variant, 2)
  #
  # Quantities are capped at available stock (unless the variant is
  # backorderable) and at MAX_PER_ITEM. Raises Carts::Manager::Error on invalid
  # input or an unpurchasable variant.
  class Manager
    class Error < StandardError; end

    MAX_PER_ITEM = 99

    def initialize(cart)
      @cart = cart
    end

    def add(variant, quantity)
      qty = quantity.to_i
      raise Error, "Quantity must be greater than zero" if qty <= 0

      validate_purchasable!(variant)
      item = @cart.cart_items.find_or_initialize_by(product_variant: variant)
      # New rows carry the column default (1); count from 0 so add(2) means 2.
      current = item.new_record? ? 0 : item.quantity
      item.quantity = clamp(current + qty, variant)
      item.save!
      item
    end

    def update(item, quantity)
      qty = quantity.to_i
      return remove(item) if qty <= 0

      validate_purchasable!(item.product_variant)
      item.update!(quantity: clamp(qty, item.product_variant))
      item
    end

    def remove(item)
      item.destroy!
      nil
    end

    # Fold another cart's items into this one (e.g. guest → customer on login),
    # summing quantities. The source cart is emptied.
    def merge(other)
      return @cart if other.nil? || other == @cart

      other.cart_items.includes(:product_variant).each do |item|
        next unless item.product_variant

        add(item.product_variant, item.quantity)
      rescue Error
        next # skip anything no longer purchasable
      end
      other.destroy!
      @cart
    end

    private

    def validate_purchasable!(variant)
      raise Error, "This item is unavailable" unless variant&.active?
      raise Error, "This product is no longer available" unless variant.product&.kept? && variant.product.active?
      raise Error, "This item is out of stock" unless variant.in_stock?
    end

    def clamp(qty, variant)
      backorderable = variant.inventory_item&.backorderable?
      ceiling = backorderable ? MAX_PER_ITEM : [ variant.available, MAX_PER_ITEM ].min
      qty.clamp(1, [ ceiling, 1 ].max)
    end
  end
end
