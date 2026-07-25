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
  end

  it "deletes a variant" do
    sign_in_admin(super_admin)
    variant = product.variants.create!
    variant.variant_option_values.create!(attribute_value: red)

    expect do
      delete "/admin/products/#{product.id}/variants/#{variant.id}"
    end.to change { product.variants.non_master.count }.by(-1)
  end
end
