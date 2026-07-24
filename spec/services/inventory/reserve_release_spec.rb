# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Inventory reservations" do
  let(:item) { create(:product_variant).inventory_item.tap { |i| i.update!(on_hand: 10) } }

  describe Inventory::Reserve do
    it "moves quantity into reserved without touching on-hand" do
      Inventory::Reserve.new(inventory_item: item, quantity: 4).call
      item.reload
      expect(item.on_hand).to eq(10)
      expect(item.reserved).to eq(4)
      expect(item.available).to eq(6)
      expect(item.stock_movements.last).to be_reason_reservation
    end

    it "blocks overselling beyond available" do
      expect { Inventory::Reserve.new(inventory_item: item, quantity: 11).call }
        .to raise_error(Inventory::Error, /Insufficient stock/)
      expect(item.reload.reserved).to eq(0)
    end

    it "allows overselling when backorderable" do
      item.update!(backorderable: true)
      expect { Inventory::Reserve.new(inventory_item: item, quantity: 999).call }.not_to raise_error
      expect(item.reload.reserved).to eq(999)
    end
  end

  describe Inventory::Release do
    it "returns quantity from reserved, capped at what is reserved" do
      Inventory::Reserve.new(inventory_item: item, quantity: 4).call
      Inventory::Release.new(inventory_item: item, quantity: 10).call
      item.reload
      expect(item.reserved).to eq(0)
      expect(item.available).to eq(10)
      expect(item.stock_movements.first).to be_reason_release
    end

    it "no-ops when nothing is reserved" do
      expect(Inventory::Release.new(inventory_item: item, quantity: 5).call).to be_nil
    end
  end
end
