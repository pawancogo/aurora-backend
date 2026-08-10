# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Checkout" do
  def data
    response.parsed_body["data"]
  end

  def stocked_variant(on_hand: 10)
    variant = create(:product_variant, :priced)
    variant.inventory_item.update!(on_hand: on_hand)
    variant
  end

  def auth_headers_for(customer)
    post "/api/v1/customer/auth/login", params: { email: customer.email, password: "password123" }, as: :json
    access = response.parsed_body.dig("data", "tokens", "access_token")
    { "Authorization" => "Bearer #{access}" }
  end

  let(:address) do
    { full_name: "Jane Doe", phone: "9999999999", line1: "123 Main St", city: "Mumbai",
      state: "Maharashtra", postal_code: "400001", country: "IN" }
  end

  it "requires authentication" do
    post "/api/v1/checkout", params: { address: address }, as: :json
    expect(response).to have_http_status(:unauthorized)
  end

  it "rejects checkout with an empty cart" do
    customer = create(:customer)
    post "/api/v1/checkout", params: { address: address }, headers: auth_headers_for(customer), as: :json
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body.dig("error", "code")).to eq("checkout_error")
  end

  it "places an order from the cart: snapshots items/address, decrements stock, clears the cart" do
    customer = create(:customer)
    auth = auth_headers_for(customer)
    variant = stocked_variant(on_hand: 10)
    shipping_method = create(:shipping_method, name: "Express", price_cents: 5000)

    post "/api/v1/cart/items", params: { variant_id: variant.id, quantity: 2 }, headers: auth, as: :json

    post "/api/v1/checkout",
         params: { shipping_method_id: shipping_method.id, address: address },
         headers: auth, as: :json

    expect(response).to have_http_status(:created)
    expect(data["order_number"]).to be_present
    expect(data["status"]).to eq("confirmed")
    expect(data["items"].length).to eq(1)
    expect(data["items"].first["quantity"]).to eq(2)
    expect(data["shipping_address"]["full_name"]).to eq("Jane Doe")
    expect(data["shipping"]).to eq(50.0)
    expect(data["total"]).to eq(data["subtotal"] + 50.0)

    expect(variant.inventory_item.reload.on_hand).to eq(8)

    get "/api/v1/cart", headers: auth
    expect(response.parsed_body.dig("data", "item_count")).to eq(0)
  end

  it "rejects an unpurchasable item at checkout time even if it was purchasable when added" do
    customer = create(:customer)
    auth = auth_headers_for(customer)
    variant = stocked_variant(on_hand: 5)
    post "/api/v1/cart/items", params: { variant_id: variant.id, quantity: 1 }, headers: auth, as: :json

    variant.inventory_item.update!(on_hand: 0)

    post "/api/v1/checkout", params: { address: address }, headers: auth, as: :json
    expect(response).to have_http_status(:unprocessable_content)
  end

  it "rejects an invalid shipping method" do
    customer = create(:customer)
    auth = auth_headers_for(customer)
    variant = stocked_variant
    post "/api/v1/cart/items", params: { variant_id: variant.id, quantity: 1 }, headers: auth, as: :json

    post "/api/v1/checkout", params: { shipping_method_id: -1, address: address }, headers: auth, as: :json
    expect(response).to have_http_status(:unprocessable_content)
  end

  it "creates the order for the signed-in customer, retrievable via order history" do
    customer = create(:customer)
    auth = auth_headers_for(customer)
    variant = stocked_variant
    post "/api/v1/cart/items", params: { variant_id: variant.id, quantity: 1 }, headers: auth, as: :json

    post "/api/v1/checkout", params: { address: address }, headers: auth, as: :json
    order_id = data["id"]

    get "/api/v1/orders", headers: auth
    expect(data.map { |o| o["id"] }).to include(order_id)

    get "/api/v1/orders/#{order_id}", headers: auth
    expect(data["id"]).to eq(order_id)
  end
end
