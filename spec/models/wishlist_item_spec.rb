# frozen_string_literal: true

require "rails_helper"

RSpec.describe WishlistItem do
  it "prevents adding the same product twice for a customer" do
    customer = create(:customer)
    product = create(:product)
    create(:wishlist_item, customer: customer, product: product)

    duplicate = WishlistItem.new(customer: customer, product: product)

    expect(duplicate).not_to be_valid
  end

  it "allows the same product on two different customers' wishlists" do
    product = create(:product)
    create(:wishlist_item, customer: create(:customer), product: product)

    other = WishlistItem.new(customer: create(:customer), product: product)

    expect(other).to be_valid
  end
end
