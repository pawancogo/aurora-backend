# frozen_string_literal: true

require "rails_helper"

RSpec.describe Payment do
  it "requires a unique razorpay_order_id" do
    existing = create(:payment)

    expect(build(:payment, razorpay_order_id: existing.razorpay_order_id)).not_to be_valid
  end

  it "exposes the amount in rupees" do
    expect(build(:payment, amount_cents: 1999).amount).to eq(19.99)
  end
end
