# frozen_string_literal: true

require "rails_helper"

RSpec.describe Products::VariantGroups do
  def linked_category(*attributes)
    category = create(:category)
    attributes.each_with_index do |attribute, i|
      CategoryAttribute.create!(category: category, product_attribute: attribute, position: i + 1)
    end
    category
  end

  let(:color) { create(:product_attribute, :color) }
  let(:size) { create(:product_attribute, :size) }

  it "groups by the cheapest variant per color, ignoring size" do
    category = linked_category(color, size)
    product = create(:product, category: category)
    red = color.attribute_values.create!(value: "Red")
    blue = color.attribute_values.create!(value: "Blue")
    small = size.attribute_values.create!(value: "S")
    medium = size.attribute_values.create!(value: "M")

    cheap_red = product.variants.create!(price_cents: 500)
    cheap_red.variant_option_values.create!(attribute_value: red)
    cheap_red.variant_option_values.create!(attribute_value: small)

    pricier_red = product.variants.create!(price_cents: 900)
    pricier_red.variant_option_values.create!(attribute_value: red)
    pricier_red.variant_option_values.create!(attribute_value: medium)

    blue_variant = product.variants.create!(price_cents: 700)
    blue_variant.variant_option_values.create!(attribute_value: blue)
    blue_variant.variant_option_values.create!(attribute_value: small)

    groups = described_class.for([ product.reload ])

    entries = groups.fetch(product.id)
    expect(entries.size).to eq(2)
    by_value = entries.index_by { |entry| entry.value.value }
    expect(by_value["Red"].variant).to eq(cheap_red)
    expect(by_value["Blue"].variant).to eq(blue_variant)
  end

  it "excludes inactive variants from a group" do
    category = linked_category(color)
    product = create(:product, category: category)
    red = color.attribute_values.create!(value: "Red")

    cheap_inactive = product.variants.create!(price_cents: 400, active: false)
    cheap_inactive.variant_option_values.create!(attribute_value: red)
    pricier_active = product.variants.create!(price_cents: 900, active: true)
    pricier_active.variant_option_values.create!(attribute_value: red)

    groups = described_class.for([ product.reload ])

    expect(groups.fetch(product.id).sole.variant).to eq(pricier_active)
  end

  it "omits products with no primary_variant_attribute entirely" do
    plain_product = create(:product)

    groups = described_class.for([ plain_product ])

    expect(groups).to be_empty
  end

  it "scopes each product to only its own primary attribute in a mixed batch" do
    tee_category = linked_category(color, size)
    jeans_category = linked_category(color, create(:product_attribute, code: "waist"))
    tee = create(:product, category: tee_category)
    jeans = create(:product, category: jeans_category)

    red = color.attribute_values.create!(value: "Red")
    tee_variant = tee.variants.create!(price_cents: 500)
    tee_variant.variant_option_values.create!(attribute_value: red)

    jeans_variant = jeans.variants.create!(price_cents: 2000)
    jeans_variant.variant_option_values.create!(attribute_value: red)

    groups = described_class.for([ tee.reload, jeans.reload ])

    expect(groups.fetch(tee.id).sole.variant).to eq(tee_variant)
    expect(groups.fetch(jeans.id).sole.variant).to eq(jeans_variant)
  end
end
