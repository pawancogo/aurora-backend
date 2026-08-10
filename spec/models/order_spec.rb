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
    expect(build(:order, status: :shipped)).not_to be_cancellable
    expect(build(:order, status: :cancelled)).not_to be_cancellable
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
