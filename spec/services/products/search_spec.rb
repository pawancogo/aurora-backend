# frozen_string_literal: true

require "rails_helper"

RSpec.describe Products::Search do
  # A product with one variant carrying the given colour value + stock.
  def product_with_color(name:, color:, value_code:, on_hand:, **attrs)
    product = create(:product, { name: name }.merge(attrs))
    product.variants.non_master.destroy_all
    value = color.attribute_values.find_by(code: value_code) || color.attribute_values.create!(value: value_code.capitalize, code: value_code)
    variant = product.variants.create!
    variant.variant_option_values.create!(attribute_value: value)
    variant.inventory_item.update!(on_hand: on_hand)
    product
  end

  let(:color) { create(:product_attribute, :color) }

  describe "attribute filter" do
    it "returns only products with a variant matching the selected value" do
      red = product_with_color(name: "Red Tee", color: color, value_code: "red", on_hand: 5)
      product_with_color(name: "Blue Tee", color: color, value_code: "blue", on_hand: 5)

      result = described_class.new(Product.kept.live, { attr: { "color" => "red" } }).call

      expect(result.records).to contain_exactly(red)
    end

    it "ANDs across different attributes" do
      size = create(:product_attribute, :size)
      medium = size.attribute_values.create!(value: "M", code: "m")
      product = product_with_color(name: "Red M Tee", color: color, value_code: "red", on_hand: 5)
      product.variants.non_master.first.variant_option_values.create!(attribute_value: medium)
      product_with_color(name: "Red only", color: color, value_code: "red", on_hand: 5)

      result = described_class.new(Product.kept.live, { attr: { "color" => "red", "size" => "m" } }).call

      expect(result.records).to contain_exactly(product)
    end
  end

  describe "in_stock filter" do
    it "keeps only products with an in-stock sellable variant" do
      stocked = product_with_color(name: "Stocked", color: color, value_code: "red", on_hand: 3)
      product_with_color(name: "Empty", color: color, value_code: "blue", on_hand: 0)

      result = described_class.new(Product.kept.live, { in_stock: "true" }).call

      expect(result.records).to contain_exactly(stocked)
    end
  end

  describe "facets" do
    it "counts colour values and availability against the browse context" do
      product_with_color(name: "Red Tee", color: color, value_code: "red", on_hand: 5)
      product_with_color(name: "Blue Tee", color: color, value_code: "blue", on_hand: 0)

      facets = described_class.new(Product.kept.live, {}).call.facets

      color_facet = facets[:attributes].find { |a| a[:code] == "color" }
      counts = color_facet[:values].to_h { |v| [ v[:code], v[:count] ] }
      expect(counts).to include("red" => 1, "blue" => 1)
      expect(facets[:availability]).to eq(1) # only the stocked one
      expect(facets[:price]).to include(:min, :max)
    end
  end

  describe "q with synonyms" do
    it "matches synonym-group members (t-shirt finds a tee)" do
      tee = create(:product, name: "Classic Cotton Tee")
      create(:product, name: "Leather Belt")

      result = described_class.new(Product.kept.live, { q: "t-shirt" }).call

      expect(result.records).to contain_exactly(tee)
    end

    it "still matches the literal term when no synonym applies" do
      match = create(:product, name: "Zephyr Runner")
      create(:product, name: "Other")

      expect(described_class.new(Product.kept.live, { q: "zephyr" }).call.records).to contain_exactly(match)
    end
  end

  it "filters by category subtree, brand, price, and q (base filters)" do
    parent = create(:category)
    child = create(:category, parent: parent)
    brand = create(:brand)
    match = create(:product, name: "Zephyr Runner", category: child, brand: brand, price_cents: 5000)
    create(:product, name: "Other", price_cents: 5000)

    expect(described_class.new(Product.kept.live, { category: parent.slug }).call.records).to include(match)
    expect(described_class.new(Product.kept.live, { brand: brand.slug }).call.records).to contain_exactly(match)
    expect(described_class.new(Product.kept.live, { q: "Zephyr" }).call.records).to contain_exactly(match)
    expect(described_class.new(Product.kept.live, { min_price: "40" }).call.records).to include(match)
  end
end
