# frozen_string_literal: true

require "rails_helper"

RSpec.describe Inventory::AdjustStock do
  let(:item) { create(:product_variant).inventory_item }

  it "increases on-hand and records a movement" do
    expect do
      described_class.new(inventory_item: item, quantity: 10, reason: :restock).call
    end.to change { item.reload.on_hand }.by(10)
      .and change(item.stock_movements, :count).by(1)

    movement = item.stock_movements.last
    expect(movement.quantity).to eq(10)
    expect(movement).to be_reason_restock
  end

  it "decreases on-hand for a sale" do
    item.update!(on_hand: 5)
    described_class.new(inventory_item: item, quantity: -2, reason: :sale).call
    expect(item.reload.on_hand).to eq(3)
  end

  it "records the acting admin" do
    admin = create(:admin_user)
    movement = described_class.new(inventory_item: item, quantity: 3, reason: :restock, actor: admin).call
    expect(movement.admin_user).to eq(admin)
  end

  it "refuses to drive on-hand negative" do
    item.update!(on_hand: 1)
    expect do
      described_class.new(inventory_item: item, quantity: -5, reason: :sale).call
    end.to raise_error(Inventory::Error, /Insufficient stock/)
    expect(item.reload.on_hand).to eq(1)
  end

  it "rejects a zero quantity and unknown reasons" do
    expect { described_class.new(inventory_item: item, quantity: 0, reason: :restock).call }
      .to raise_error(Inventory::Error, /non-zero/)
    expect { described_class.new(inventory_item: item, quantity: 5, reason: :reservation).call }
      .to raise_error(Inventory::Error, /Unknown on-hand reason/)
  end
end
