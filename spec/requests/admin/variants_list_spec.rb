# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin global variants list", type: :request do
  def sign_in_admin(admin, password = "password1234")
    post "/admin/login", params: { email: admin.email, password: password }
  end

  let(:super_admin) { create(:admin_user, :super_admin, password: "password1234") }
  let(:color) { create(:product_attribute, :color) }
  let(:red) { color.attribute_values.create!(value: "Red") }

  def variant_for(product_name)
    product = create(:product, name: product_name)
    variant = product.variants.create!(sku: "VAR-#{product_name.parameterize}")
    variant.variant_option_values.create!(attribute_value: red)
    variant
  end

  it "lists variants across products with product name and SKU" do
    sign_in_admin(super_admin)
    variant = variant_for("Trail Runner")

    get "/admin/variants"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Trail Runner")
    expect(response.body).to include(variant.sku)
  end

  it "excludes master variants" do
    sign_in_admin(super_admin)
    product = create(:product) # only a master variant

    get "/admin/variants"

    expect(response.body).not_to include(product.master_variant.sku)
  end

  it "searches by product name or SKU" do
    sign_in_admin(super_admin)
    keep = variant_for("Alpha Shoe")
    other = variant_for("Beta Shirt")

    get "/admin/variants", params: { q: "Alpha" }

    expect(response.body).to include(keep.sku)
    expect(response.body).not_to include(other.sku)
  end

  it "filters by option value (e.g. Color = Red)" do
    sign_in_admin(super_admin)
    product = create(:product, name: "Multi")
    blue = color.attribute_values.create!(value: "Blue")
    red_v = product.variants.create!(sku: "VAR-RED")
    red_v.variant_option_values.create!(attribute_value: red)
    blue_v = product.variants.create!(sku: "VAR-BLUE")
    blue_v.variant_option_values.create!(attribute_value: blue)

    get "/admin/variants", params: { opt: { color.id.to_s => red.id.to_s } }

    expect(response.body).to include("VAR-RED")
    expect(response.body).not_to include("VAR-BLUE")
  end

  it "filters by stock status" do
    sign_in_admin(super_admin)
    stocked = variant_for("Stocked One")
    stocked.inventory_item.update!(on_hand: 5)
    empty = variant_for("Empty One") # auto inventory, 0 on hand

    get "/admin/variants", params: { stock: "out" }

    expect(response.body).to include(empty.sku)
    expect(response.body).not_to include(stocked.sku)
  end

  it "requires products.read" do
    plain = create(:admin_user, password: "password1234")
    sign_in_admin(plain)

    get "/admin/variants"

    expect(response).to redirect_to("/admin")
  end
end
