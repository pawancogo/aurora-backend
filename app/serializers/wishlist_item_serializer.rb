# frozen_string_literal: true

# A saved-for-later product on the customer's wishlist.
class WishlistItemSerializer
  def self.collection(items)
    items.map { |item| new(item).as_json }
  end

  def initialize(item)
    @item = item
  end

  def as_json(*)
    {
      id: @item.id,
      added_at: @item.created_at,
      product: ProductListSerializer.new(@item.product).as_json
    }
  end
end
