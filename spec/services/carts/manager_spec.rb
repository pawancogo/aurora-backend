# frozen_string_literal: true

require "rails_helper"

RSpec.describe Carts::Manager do
  def stocked_variant(on_hand: 25)
    variant = create(:product_variant, :priced)
    variant.inventory_item.update!(on_hand: on_hand)
    variant
  end

  let(:cart) { Cart.create! }
  subject(:manager) { described_class.new(cart) }

  describe "#add" do
    it "sets the exact quantity for a new line, then increments it" do
      variant = stocked_variant
      manager.add(variant, 2)
      expect(cart.cart_items.first.quantity).to eq(2)

      manager.add(variant, 3)
      expect(cart.cart_items.reload.first.quantity).to eq(5)
    end

    it "caps quantity at available stock when not backorderable" do
      item = manager.add(stocked_variant(on_hand: 3), 10)
      expect(item.quantity).to eq(3)
    end

    it "raises for an out-of-stock variant" do
      expect { manager.add(stocked_variant(on_hand: 0), 1) }.to raise_error(described_class::Error)
    end

    it "rejects non-positive quantities" do
      expect { manager.add(stocked_variant, 0) }.to raise_error(described_class::Error)
    end
  end

  describe "#update" do
    it "removes the line when quantity drops to zero" do
      item = manager.add(stocked_variant, 2)
      manager.update(item, 0)
      expect(cart.cart_items.count).to eq(0)
    end
  end

  describe "#merge" do
    it "folds another cart's items in (summing quantities) and destroys the source" do
      variant = stocked_variant
      other = Cart.create!
      described_class.new(other).add(variant, 2)
      manager.add(variant, 1)

      manager.merge(other)

      expect(cart.cart_items.first.quantity).to eq(3)
      expect(Cart.exists?(other.id)).to be(false)
    end
  end
end
