# frozen_string_literal: true

require "rails_helper"

RSpec.describe InventoryItem do
  let(:item) { create(:product_variant).inventory_item }

  describe "#available" do
    it "is on_hand minus reserved" do
      item.update!(on_hand: 10, reserved: 3)
      expect(item.available).to eq(7)
    end
  end

  describe "#in_stock?" do
    it "is true when available is positive" do
      item.update!(on_hand: 1)
      expect(item).to be_in_stock
    end

    it "is false at zero available unless backorderable" do
      item.update!(on_hand: 0)
      expect(item).not_to be_in_stock
      item.update!(backorderable: true)
      expect(item).to be_in_stock
    end
  end

  describe "#low_stock?" do
    it "is true at or under a positive threshold" do
      item.update!(on_hand: 2, low_stock_threshold: 2)
      expect(item).to be_low_stock
    end

    it "is off when the threshold is zero" do
      item.update!(on_hand: 0, low_stock_threshold: 0)
      expect(item).not_to be_low_stock
    end
  end

  describe "scopes" do
    it ".low_stock returns items at/under their threshold" do
      low = create(:product_variant).inventory_item.tap { |i| i.update!(on_hand: 1, low_stock_threshold: 5) }
      create(:product_variant).inventory_item.update!(on_hand: 50, low_stock_threshold: 5)

      expect(InventoryItem.low_stock).to include(low)
      expect(InventoryItem.low_stock.count).to eq(1)
    end
  end

  it "rejects negative quantities" do
    item.reserved = -1
    expect(item).not_to be_valid
  end
end
