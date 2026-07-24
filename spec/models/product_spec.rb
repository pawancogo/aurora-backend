# frozen_string_literal: true

require "rails_helper"

RSpec.describe Product do
  it "auto-generates a slug from the name" do
    product = create(:product, name: "Cool Sneaker!")
    expect(product.slug).to eq("cool-sneaker")
  end

  it "computes discount_percent from mrp and price" do
    product = build(:product, price_cents: 800, mrp_cents: 1000)
    expect(product.discount_percent).to eq(20)
  end

  it "returns zero discount when price >= mrp" do
    product = build(:product, price_cents: 1000, mrp_cents: 1000)
    expect(product.discount_percent).to eq(0)
  end

  describe ".live" do
    it "excludes draft and not-yet-published products" do
      live = create(:product)
      create(:product, :draft)
      create(:product, :scheduled)

      expect(Product.live).to contain_exactly(live)
    end
  end

  it "requires a unique SKU" do
    create(:product, sku: "DUP-1")
    expect(build(:product, sku: "DUP-1")).not_to be_valid
  end

  describe "SKU auto-generation" do
    it "generates a SKU when none is provided" do
      product = Product.create!(name: "No SKU")
      expect(product.sku).to match(/\ASKU-[A-Z0-9]{8}\z/)
    end

    it "generates distinct SKUs across products" do
      skus = Array.new(5) { Product.create!(name: "Bulk").sku }
      expect(skus.uniq.size).to eq(5)
    end

    it "keeps a manually supplied SKU" do
      expect(Product.create!(name: "Manual", sku: "MANUAL-1").sku).to eq("MANUAL-1")
    end
  end
end
