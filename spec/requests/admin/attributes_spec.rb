# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin attributes management", type: :request do
  def sign_in_admin(admin, password = "password1234")
    post "/admin/login", params: { email: admin.email, password: password }
  end

  let(:super_admin) { create(:admin_user, :super_admin, password: "password1234") }

  it "lists attributes" do
    sign_in_admin(super_admin)
    attribute = create(:product_attribute, name: "Material")

    get "/admin/attributes"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Material")
  end

  it "creates an attribute with nested values" do
    sign_in_admin(super_admin)

    expect do
      post "/admin/attributes", params: {
        product_attribute: {
          name: "Color", filterable: "1",
          attribute_values_attributes: { "0" => { value: "Red" }, "1" => { value: "Blue" }, "2" => { value: "" } }
        }
      }
    end.to change(ProductAttribute, :count).by(1)

    attribute = ProductAttribute.find_by(code: "color")
    expect(attribute.attribute_values.map(&:value)).to contain_exactly("Red", "Blue")
    expect(attribute.filterable).to be(true)
    expect(response).to redirect_to("/admin/attributes")
  end

  it "won't delete an attribute whose values are used by variants" do
    sign_in_admin(super_admin)
    product = create(:product)
    color = create(:product_attribute, :color)
    red = color.attribute_values.create!(value: "Red")
    product.variants.create! { |v| v.variant_option_values.build(attribute_value: red) }

    expect { delete "/admin/attributes/#{color.id}" }.not_to change(ProductAttribute, :count)
    expect(response).to redirect_to("/admin/attributes")
    expect(flash[:alert]).to match(/used by variants/)
  end

  it "requires products.manage to create" do
    plain = create(:admin_user, password: "password1234")
    sign_in_admin(plain)

    expect do
      post "/admin/attributes", params: { product_attribute: { name: "Nope" } }
    end.not_to change(ProductAttribute, :count)
  end
end
