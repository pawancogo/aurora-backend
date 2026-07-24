# frozen_string_literal: true

require "rails_helper"

RSpec.describe Products::Query do
  it "filters by a category and its descendants" do
    men = create(:category)
    topwear = create(:category, parent: men)
    in_subtree = create(:product, category: topwear)
    elsewhere = create(:product, category: create(:category))

    result = described_class.new(Product.all, { category: men.slug }).call

    expect(result).to include(in_subtree)
    expect(result).not_to include(elsewhere)
  end

  it "filters by brand" do
    brand = create(:brand)
    matching = create(:product, brand: brand)
    create(:product, brand: create(:brand))

    result = described_class.new(Product.all, { brand: brand.slug }).call

    expect(result).to contain_exactly(matching)
  end

  it "searches by name" do
    match = create(:product, name: "Blue Widget")
    create(:product, name: "Red Gadget")

    result = described_class.new(Product.all, { q: "widget" }).call

    expect(result).to contain_exactly(match)
  end

  it "sorts by price ascending" do
    cheap = create(:product, price_cents: 100)
    pricey = create(:product, price_cents: 9999)

    result = described_class.new(Product.all, { sort: "price_asc" }).call.to_a

    expect(result.index(cheap)).to be < result.index(pricey)
  end
end
