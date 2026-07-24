# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Admin::Products", type: :request do
  def token_for(permission_keys)
    role = create(:role)
    permission_keys.each do |key|
      role.permissions << Permission.find_or_create_by!(key: key) { |p| p.name = key }
    end
    admin = create(:admin_user)
    admin.roles << role
    Auth::IssueTokenPair.new(admin).call.access_token
  end

  def auth(permission_keys)
    { "Authorization" => "Bearer #{token_for(permission_keys)}" }
  end

  it "creates a product (with images) for products.manage" do
    brand = create(:brand)
    category = create(:category)

    post "/api/v1/admin/products",
         params: {
           product: {
             name: "New Product", sku: "NP-1", price_cents: 500, mrp_cents: 800,
             brand_id: brand.id, category_id: category.id, status: "active",
             product_images_attributes: [ { source_url: "https://example.com/a.jpg", primary: true } ]
           }
         },
         headers: auth(%w[products.read products.manage]), as: :json

    expect(response).to have_http_status(:created)
    expect(Product.find_by(sku: "NP-1").product_images.count).to eq(1)
  end

  it "forbids creation without products.manage" do
    post "/api/v1/admin/products",
         params: { product: { name: "X", sku: "X-1" } },
         headers: auth(%w[products.read]), as: :json

    expect(response).to have_http_status(:forbidden)
  end

  it "archives (soft-deletes) a product on destroy" do
    product = create(:product)

    delete "/api/v1/admin/products/#{product.id}", headers: auth(%w[products.read products.manage])

    expect(response).to have_http_status(:ok)
    expect(product.reload.discarded?).to be(true)
  end

  it "includes drafts in the admin index" do
    create(:product, :draft, name: "Draft Product")

    get "/api/v1/admin/products", headers: auth(%w[products.read])

    expect(response.parsed_body["data"].map { |p| p["name"] }).to include("Draft Product")
  end
end
