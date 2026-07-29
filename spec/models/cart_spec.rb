# frozen_string_literal: true

require "rails_helper"

RSpec.describe Cart do
  it "auto-generates a unique token on create" do
    cart = Cart.create!
    expect(cart.token).to be_present
  end

  it "computes item_count and subtotal from live variant prices" do
    cart = Cart.create!
    variant = create(:product_variant, :priced) # price_cents 1500
    cart.cart_items.create!(product_variant: variant, quantity: 2)

    expect(cart.item_count).to eq(2)
    expect(cart.subtotal_cents).to eq(3000)
  end
end
