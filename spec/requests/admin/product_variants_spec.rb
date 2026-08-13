# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin product variants", type: :request do
  def sign_in_admin(admin, password = "password1234")
    post "/admin/login", params: { email: admin.email, password: password }
  end

  let(:super_admin) { create(:admin_user, :super_admin, password: "password1234") }
  let(:product) { create(:product, price_cents: 1000, mrp_cents: 2000) }
  let(:color) { create(:product_attribute, :color) }
  let(:red) { color.attribute_values.create!(value: "Red") }

  it "creates a variant with an option, price, and initial stock" do
    sign_in_admin(super_admin)

    expect do
      post "/admin/products/#{product.id}/variants", params: {
        product_variant: { price: "12.50", active: "1" },
        option_values: { color.id.to_s => red.id.to_s },
        initial_stock: "5"
      }
    end.to change { product.variants.non_master.count }.by(1)

    variant = product.variants.non_master.last
    expect(variant.price_cents).to eq(1250)
    expect(variant.attribute_values).to include(red)
    expect(variant.inventory_item.on_hand).to eq(5)
    expect(response).to redirect_to("/admin/products/#{product.id}/variants")
  end

  it "rejects a variant with no options" do
    sign_in_admin(super_admin)
    product # force creation (auto-makes its master variant) before the assertion

    expect do
      post "/admin/products/#{product.id}/variants", params: { product_variant: { price: "5" }, option_values: {} }
    end.not_to change { product.variants.non_master.count }
    expect(response).to have_http_status(:unprocessable_content)
  end

  it "rejects a duplicate option combination" do
    sign_in_admin(super_admin)
    first = product.variants.create!
    first.variant_option_values.create!(attribute_value: red)

    expect do
      post "/admin/products/#{product.id}/variants", params: {
        product_variant: {}, option_values: { color.id.to_s => red.id.to_s }
      }
    end.not_to change { product.variants.non_master.count }
    expect(response.body).to include("same options")
    expect(response.body).to include("##{first.id}")
    expect(response.body).to include(first.sku)
  end

  it "deletes a variant" do
    sign_in_admin(super_admin)
    variant = product.variants.create!
    variant.variant_option_values.create!(attribute_value: red)

    expect do
      delete "/admin/products/#{product.id}/variants/#{variant.id}"
    end.to change { product.variants.non_master.count }.by(-1)
  end

  it "prefills price, MRP, and active status from a copy_from_id variant on the new-variant form" do
    sign_in_admin(super_admin)
    source = product.variants.create!(price_cents: 1_250, mrp_cents: 1_800, active: false)
    source.variant_option_values.create!(attribute_value: red)

    get "/admin/products/#{product.id}/variants/new", params: { copy_from_id: source.id }

    expect(response.body).to include('value="12.5"')
    expect(response.body).to include('value="18.0"')
    expect(response.body).to include("Prefilled price, MRP and active status from")
  end

  it "prefills from copy_from_select when no id is typed in" do
    sign_in_admin(super_admin)
    source = product.variants.create!(price_cents: 1_250, mrp_cents: 1_800)
    source.variant_option_values.create!(attribute_value: red)

    get "/admin/products/#{product.id}/variants/new", params: { copy_from_select: source.id }

    expect(response.body).to include('value="12.5"')
  end

  it "prioritizes the typed id over the dropdown when both are present" do
    sign_in_admin(super_admin)
    blue = color.attribute_values.create!(value: "Blue")
    by_id = product.variants.create!(price_cents: 1_250)
    by_id.variant_option_values.create!(attribute_value: red)
    from_dropdown = product.variants.create!(price_cents: 900)
    from_dropdown.variant_option_values.create!(attribute_value: blue)

    get "/admin/products/#{product.id}/variants/new",
        params: { copy_from_id: by_id.id, copy_from_select: from_dropdown.id }

    expect(response.body).to include('value="12.5"')
    expect(response.body).not_to include('value="9.0"')
  end

  it "flags a copy_from_id that doesn't belong to the product, without prefilling" do
    sign_in_admin(super_admin)
    other_product = create(:product)
    other_variant = other_product.variants.create!(price_cents: 999)

    get "/admin/products/#{product.id}/variants/new", params: { copy_from_id: other_variant.id }

    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include('value="9.99"')
    expect(response.body).to include("No variant with that ID exists on this product")
  end

  it "offers only the attributes scoped to the product's category on the new-variant form" do
    sign_in_admin(super_admin)
    size = create(:product_attribute, :size)
    size.attribute_values.create!(value: "M")
    red # ensure Color has a value
    category = create(:category)
    category.variant_attributes = [ color ] # only Color scoped to this category
    scoped_product = create(:product, category: category)

    get "/admin/products/#{scoped_product.id}/variants/new"

    expect(response.body).to include("Color")
    expect(response.body).not_to include(">Size<") # the Size option group label
  end
end

RSpec.describe "Admin category → attribute links", type: :request do
  def sign_in_admin(admin, password = "password1234")
    post "/admin/login", params: { email: admin.email, password: password }
  end

  it "links variant attributes to a category" do
    admin = create(:admin_user, :super_admin, password: "password1234")
    sign_in_admin(admin)
    color = create(:product_attribute, :color)
    category = create(:category, name: "Footwear")

    patch "/admin/categories/#{category.id}",
          params: { category: { name: "Footwear", variant_attribute_ids: [ "", color.id.to_s ] } }

    expect(category.reload.variant_attributes).to contain_exactly(color)
  end
end
