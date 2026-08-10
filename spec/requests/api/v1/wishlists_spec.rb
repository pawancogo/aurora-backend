# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Wishlists" do
  def data
    response.parsed_body["data"]
  end

  def meta
    response.parsed_body["meta"]
  end

  def auth_headers_for(customer)
    post "/api/v1/customer/auth/login", params: { email: customer.email, password: "password123" }, as: :json
    access = response.parsed_body.dig("data", "tokens", "access_token")
    { "Authorization" => "Bearer #{access}" }
  end

  it "requires authentication" do
    get "/api/v1/wishlist"
    expect(response).to have_http_status(:unauthorized)
  end

  it "adds, lists, and removes a product for the signed-in customer" do
    customer = create(:customer)
    product = create(:product)
    auth = auth_headers_for(customer)

    post "/api/v1/wishlist/items", params: { product_id: product.id }, headers: auth, as: :json
    expect(response).to have_http_status(:created)
    expect(data["product"]["id"]).to eq(product.id)

    get "/api/v1/wishlist", headers: auth
    expect(data.length).to eq(1)
    expect(data.first["product"]["id"]).to eq(product.id)

    delete "/api/v1/wishlist/items/#{product.id}", headers: auth
    expect(response).to have_http_status(:ok)
    expect(data["product_id"]).to eq(product.id)

    get "/api/v1/wishlist", headers: auth
    expect(data).to eq([])
  end

  it "is idempotent when adding the same product twice" do
    customer = create(:customer)
    product = create(:product)
    auth = auth_headers_for(customer)

    2.times { post "/api/v1/wishlist/items", params: { product_id: product.id }, headers: auth, as: :json }

    get "/api/v1/wishlist", headers: auth
    expect(data.length).to eq(1)
  end

  it "scopes the wishlist to each customer" do
    product = create(:product)
    customer_a = create(:customer)
    customer_b = create(:customer)

    post "/api/v1/wishlist/items", params: { product_id: product.id }, headers: auth_headers_for(customer_a), as: :json

    get "/api/v1/wishlist", headers: auth_headers_for(customer_b)
    expect(data).to eq([])
  end

  it "paginates a large wishlist" do
    customer = create(:customer)
    auth = auth_headers_for(customer)
    create_list(:product, 15).each do |product|
      post "/api/v1/wishlist/items", params: { product_id: product.id }, headers: auth, as: :json
    end

    get "/api/v1/wishlist", params: { per_page: 10 }, headers: auth
    expect(data.length).to eq(10)
    expect(meta).to include("current_page" => 1, "per_page" => 10, "total_pages" => 2, "total_count" => 15)

    get "/api/v1/wishlist", params: { page: 2, per_page: 10 }, headers: auth
    expect(data.length).to eq(5)
    expect(meta["current_page"]).to eq(2)
  end

  it "lists every wishlisted product id, unpaginated" do
    customer = create(:customer)
    auth = auth_headers_for(customer)
    products = create_list(:product, 3)
    products.each { |product| post "/api/v1/wishlist/items", params: { product_id: product.id }, headers: auth, as: :json }

    get "/api/v1/wishlist/product_ids", headers: auth
    expect(data).to match_array(products.map(&:id))
  end
end
