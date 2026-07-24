# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProductVariant do
  describe "master variant" do
    it "is auto-created for every product, with an inventory item" do
      product = create(:product)
      master = product.master_variant

      expect(master).to be_present
      expect(master).to be_is_master
      expect(master.inventory_item).to be_present
    end

    it "rejects options on the master variant" do
      product = create(:product)
      master = product.master_variant
      master.variant_option_values.build(attribute_value: create(:attribute_value))

      expect(master).not_to be_valid
      expect(master.errors[:base]).to include("The master variant cannot have options")
    end
  end

  describe "SKU" do
    it "auto-generates a unique VAR-prefixed SKU" do
      variant = create(:product_variant)
      expect(variant.sku).to match(/\AVAR-[A-Z0-9]{8}\z/)
    end

    it "keeps a manually supplied SKU" do
      expect(create(:product_variant, sku: "MANUAL-1").sku).to eq("MANUAL-1")
    end
  end

  describe "price fallback" do
    let(:product) { create(:product, price_cents: 1000, mrp_cents: 2000) }

    it "inherits the product price when unset" do
      variant = product.variants.create!
      expect(variant.price_cents_effective).to eq(1000)
      expect(variant.mrp_cents_effective).to eq(2000)
    end

    it "uses its own price when set" do
      variant = product.variants.create!(price_cents: 1500)
      expect(variant.price_cents_effective).to eq(1500)
      expect(variant.mrp_cents_effective).to eq(2000)
    end
  end

  describe "option combination uniqueness" do
    it "rejects a second variant with the identical option set" do
      product = create(:product)
      color = create(:product_attribute, :color)
      red = color.attribute_values.create!(value: "Red")

      first = product.variants.create!
      first.variant_option_values.create!(attribute_value: red)

      dup = product.variants.build
      dup.variant_option_values.build(attribute_value: red)

      expect(dup).not_to be_valid
      expect(dup.errors[:base]).to include("A variant with the same options already exists")
    end

    it "allows different option sets on the same product" do
      product = create(:product)
      color = create(:product_attribute, :color)
      red = color.attribute_values.create!(value: "Red")
      blue = color.attribute_values.create!(value: "Blue")

      product.variants.create! { |v| v.variant_option_values.build(attribute_value: red) }
      second = product.variants.build { |v| v.variant_option_values.build(attribute_value: blue) }

      expect(second).to be_valid
    end
  end
end
