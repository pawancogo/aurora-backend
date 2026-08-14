# frozen_string_literal: true

require "rails_helper"

RSpec.describe Order do
  it "auto-generates a unique order number" do
    order = create(:order)
    expect(order.order_number).to match(/\AORD-[A-Z0-9]{10}\z/)
  end

  it "is cancellable while pending or confirmed, not otherwise" do
    expect(build(:order, status: :pending)).to be_cancellable
    expect(build(:order, status: :confirmed)).to be_cancellable
    expect(build(:order, status: :accepted)).not_to be_cancellable
    expect(build(:order, status: :ready_to_ship)).not_to be_cancellable
    expect(build(:order, status: :shipped)).not_to be_cancellable
    expect(build(:order, status: :cancelled)).not_to be_cancellable
  end

  describe "#next_status" do
    it "walks the fulfillment sequence forward" do
      expect(build(:order, status: :confirmed).next_status).to eq("accepted")
      expect(build(:order, status: :accepted).next_status).to eq("ready_to_ship")
      expect(build(:order, status: :ready_to_ship).next_status).to eq("shipped")
      expect(build(:order, status: :shipped).next_status).to eq("delivered")
    end

    it "is nil once delivered, or for statuses outside the sequence" do
      expect(build(:order, status: :delivered).next_status).to be_nil
      expect(build(:order, status: :pending).next_status).to be_nil
      expect(build(:order, status: :cancelled).next_status).to be_nil
    end
  end

  describe "#cancel!" do
    it "cancels a cancellable order and releases reserved stock" do
      order = create(:order, status: :confirmed)
      variant = create(:product_variant)
      variant.inventory_item.update!(on_hand: 10, reserved: 2)
      create(:order_item, order: order, product_variant: variant, quantity: 2)

      expect(order.cancel!).to be true

      expect(order.reload).to be_cancelled
      expect(order.cancelled_at).to be_present
      expect(variant.inventory_item.reload.reserved).to eq(0)
    end

    it "returns false and does nothing when not cancellable" do
      order = create(:order, status: :accepted)

      expect(order.cancel!).to be false
      expect(order.reload).to be_accepted
      expect(order.cancelled_at).to be_nil
    end
  end

  it "is admin-cancellable through ready_to_ship, but not once shipped" do
    expect(build(:order, status: :pending)).to be_admin_cancellable
    expect(build(:order, status: :confirmed)).to be_admin_cancellable
    expect(build(:order, status: :accepted)).to be_admin_cancellable
    expect(build(:order, status: :ready_to_ship)).to be_admin_cancellable
    expect(build(:order, status: :shipped)).not_to be_admin_cancellable
    expect(build(:order, status: :delivered)).not_to be_admin_cancellable
    expect(build(:order, status: :cancelled)).not_to be_admin_cancellable
  end

  describe "#admin_cancel!" do
    it "cancels an order staff have already accepted, releasing reserved stock" do
      order = create(:order, status: :accepted)
      variant = create(:product_variant)
      variant.inventory_item.update!(on_hand: 10, reserved: 2)
      create(:order_item, order: order, product_variant: variant, quantity: 2)

      expect(order.admin_cancel!).to be true

      expect(order.reload).to be_cancelled
      expect(order.cancelled_at).to be_present
      expect(variant.inventory_item.reload.reserved).to eq(0)
    end

    it "returns false and does nothing once shipped" do
      order = create(:order, status: :shipped)

      expect(order.admin_cancel!).to be false
      expect(order.reload).to be_shipped
      expect(order.cancelled_at).to be_nil
    end
  end

  it "exposes money fields in rupees" do
    order = build(:order, subtotal_cents: 1999, shipping_cents: 100, total_cents: 2099)
    expect(order.subtotal).to eq(19.99)
    expect(order.shipping).to eq(1.0)
    expect(order.total).to eq(20.99)
  end

  it "resolves the shipping address snapshot" do
    order = create(:order)
    address = create(:order_address, order: order)
    expect(order.shipping_address).to eq(address)
  end
end
