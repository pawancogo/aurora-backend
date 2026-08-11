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

  describe "price_cents/mrp_cents (cached from variants)" do
    it "has no price until a variant sets one" do
      product = create(:product, price_cents: 0, mrp_cents: 0)
      expect(product.price_cents).to eq(0)
    end

    it "picks up the master variant's price once one is set" do
      product = create(:product)
      product.master_variant.update!(price_cents: 1000, mrp_cents: 2000)

      expect(product.reload.price_cents).to eq(1000)
      expect(product.discount_percent).to eq(50)
    end

    it "tracks the cheapest sellable variant, not just whichever was created first" do
      product = create(:product)
      create(:product_variant, product: product, price_cents: 900)
      create(:product_variant, product: product, price_cents: 600, mrp_cents: 1200)

      expect(product.reload.price_cents).to eq(600)
      expect(product.reload.mrp_cents).to eq(1200)
    end

    it "re-syncs when the cheapest variant is deactivated" do
      product = create(:product)
      cheap = create(:product_variant, product: product, price_cents: 600)
      create(:product_variant, product: product, price_cents: 900)

      cheap.update!(active: false)

      expect(product.reload.price_cents).to eq(900)
    end
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

  describe "variants & inventory" do
    it "auto-creates a master variant on create" do
      product = create(:product)
      expect(product.variants.master.count).to eq(1)
      expect(product).not_to have_variants
    end

    it "reports has_variants? once a real variant exists" do
      product = create(:product)
      product.variants.create!(price_cents: 500)
      expect(product.reload).to have_variants
    end

    it "exposes the distinct option attributes, registry-ordered" do
      product = create(:product)
      color = create(:product_attribute, :color, position: 1)
      size = create(:product_attribute, :size, position: 2)
      red = color.attribute_values.create!(value: "Red")
      medium = size.attribute_values.create!(value: "M")

      variant = product.variants.create!
      variant.variant_option_values.create!(attribute_value: red)
      variant.variant_option_values.create!(attribute_value: medium)

      expect(product.option_attributes.map(&:name)).to eq(%w[Color Size])
    end

    it "sums available stock across sellable variants" do
      product = create(:product)
      v1 = product.variants.create!(price_cents: 500)
      v2 = product.variants.create!(price_cents: 600)
      v1.inventory_item.update!(on_hand: 4)
      v2.inventory_item.update!(on_hand: 6, reserved: 1)

      expect(product.total_available).to eq(9)
      expect(product).to be_in_stock
    end
  end

  describe "#applicable_attributes" do
    def attr_with_value(trait_or_name)
      attribute = trait_or_name.is_a?(Symbol) ? create(:product_attribute, trait_or_name) : create(:product_attribute, name: trait_or_name)
      attribute.attribute_values.create!(value: "v")
      attribute
    end

    it "is scoped to the attributes linked to the product's category" do
      color = attr_with_value(:color)
      size = attr_with_value(:size)
      attr_with_value("Shoe Size") # exists but not linked
      category = create(:category)
      category.variant_attributes = [ color, size ]

      product = create(:product, category: category)
      expect(product.applicable_attributes.map(&:name)).to contain_exactly("Color", "Size")
    end

    it "inherits attribute links from an ancestor category" do
      color = attr_with_value(:color)
      parent = create(:category)
      child = create(:category, parent: parent)
      parent.variant_attributes = [ color ]

      product = create(:product, category: child)
      expect(product.applicable_attributes.map(&:name)).to eq([ "Color" ])
    end

    it "falls back to all attributes with values when the category has no links" do
      color = attr_with_value(:color)
      create(:product_attribute) # no values → excluded from the fallback
      product = create(:product, category: create(:category))

      expect(product.applicable_attributes.map(&:name)).to eq([ "Color" ])
    end
  end
end
