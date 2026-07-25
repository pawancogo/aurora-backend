# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1 product detail — variants & inventory", type: :request do
  it "exposes options, variants, stock, specs and related products" do
    product = create(:product, name: "Tee", price_cents: 1000, mrp_cents: 2000)
    color = create(:product_attribute, :color)
    red = color.attribute_values.create!(value: "Red")
    blue = color.attribute_values.create!(value: "Blue")

    red_variant = product.variants.create!(price_cents: 1200)
    red_variant.variant_option_values.create!(attribute_value: red)
    red_variant.inventory_item.update!(on_hand: 5)
    blue_variant = product.variants.create!(price_cents: 1500)
    blue_variant.variant_option_values.create!(attribute_value: blue)
    blue_variant.inventory_item.update!(on_hand: 0)

    product.specifications.create!(name: "Material", value: "Cotton")
    related = create(:product, name: "Cap")
    ProductRelation.create!(product: product, related_product: related, relation_kind: :recommended)

    get "/api/v1/products/#{product.slug}"

    expect(response).to have_http_status(:ok)
    data = response.parsed_body["data"]

    expect(data["has_variants"]).to be(true)
    expect(data["in_stock"]).to be(true)
    expect(data["total_available"]).to eq(5)
    expect(data["price_range"]).to eq("min" => 12.0, "max" => 15.0)

    expect(data["options"].first["name"]).to eq("Color")
    expect(data["options"].first["values"].map { |v| v["value"] }).to contain_exactly("Red", "Blue")

    expect(data["variants"].size).to eq(2)
    expect(data["variants"].map { |v| v["available"] }).to contain_exactly(5, 0)

    expect(data["specifications"]).to eq([ { "name" => "Material", "value" => "Cotton", "group" => nil } ])
    expect(data["related_products"].map { |r| r["name"] }).to eq([ "Cap" ])
  end

  it "represents an option-less product via its master variant" do
    product = create(:product, price_cents: 500)
    product.master_variant.inventory_item.update!(on_hand: 3)

    get "/api/v1/products/#{product.slug}"
    data = response.parsed_body["data"]

    expect(data["has_variants"]).to be(false)
    expect(data["options"]).to eq([])
    expect(data["variants"].size).to eq(1)
    expect(data["in_stock"]).to be(true)
    expect(data["total_available"]).to eq(3)
  end

  it "hides discarded or inactive related products" do
    product = create(:product)
    archived = create(:product, status: :archived)
    ProductRelation.create!(product: product, related_product: archived, relation_kind: :related)

    get "/api/v1/products/#{product.slug}"
    expect(response.parsed_body["data"]["related_products"]).to eq([])
  end
end
