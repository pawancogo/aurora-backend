# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Carts" do
  def stocked_variant(on_hand: 10)
    variant = create(:product_variant, :priced)
    variant.inventory_item.update!(on_hand: on_hand)
    variant
  end

  def data
    response.parsed_body["data"]
  end

  describe "guest cart" do
    it "creates a cart on first add and returns a token" do
      variant = stocked_variant
      post "/api/v1/cart/items", params: { variant_id: variant.id, quantity: 2 }, as: :json

      expect(response).to have_http_status(:created)
      expect(data["token"]).to be_present
      expect(data["item_count"]).to eq(2)
    end

    it "returns an empty cart when no token is supplied" do
      get "/api/v1/cart"
      expect(data["item_count"]).to eq(0)
      expect(data["items"]).to eq([])
    end

    it "re-identifies the cart by its token across requests" do
      variant = stocked_variant
      post "/api/v1/cart/items", params: { variant_id: variant.id, quantity: 1 }, as: :json
      token = data["token"]
      item_id = data["items"].first["id"]

      get "/api/v1/cart", headers: { "X-Cart-Token" => token }
      expect(data["item_count"]).to eq(1)

      patch "/api/v1/cart/items/#{item_id}", params: { quantity: 3 }, headers: { "X-Cart-Token" => token }, as: :json
      expect(data["item_count"]).to eq(3)

      delete "/api/v1/cart/items/#{item_id}", headers: { "X-Cart-Token" => token }
      expect(data["item_count"]).to eq(0)
    end

    it "rejects an out-of-stock add with a 422" do
      variant = stocked_variant(on_hand: 0)
      post "/api/v1/cart/items", params: { variant_id: variant.id, quantity: 1 }, as: :json
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "never resolves a customer-owned cart's token via the guest lookup" do
      customer = create(:customer)
      customer_cart = Cart.create!(customer: customer)

      get "/api/v1/cart", headers: { "X-Cart-Token" => customer_cart.token }

      expect(data["id"]).to be_nil
      expect(data["token"]).not_to eq(customer_cart.token)
    end
  end

  describe "signed-in cart" do
    it "binds the cart to the authenticated customer" do
      customer = create(:customer)
      post "/api/v1/customer/auth/login", params: { email: customer.email, password: "password123" }, as: :json
      access = response.parsed_body.dig("data", "tokens", "access_token")
      auth = { "Authorization" => "Bearer #{access}" }
      variant = stocked_variant

      post "/api/v1/cart/items", params: { variant_id: variant.id, quantity: 1 }, headers: auth, as: :json
      expect(data["item_count"]).to eq(1)

      get "/api/v1/cart", headers: auth
      expect(data["item_count"]).to eq(1)
      expect(Cart.find_by(customer: customer)).to be_present
    end
  end

  describe "guest cart merge on login" do
    it "folds the guest cart into the customer's cart" do
      customer = create(:customer)
      variant = stocked_variant

      post "/api/v1/cart/items", params: { variant_id: variant.id, quantity: 2 }, as: :json
      guest_token = data["token"]

      post "/api/v1/customer/auth/login",
           params: { email: customer.email, password: "password123" },
           headers: { "X-Cart-Token" => guest_token }, as: :json
      access = response.parsed_body.dig("data", "tokens", "access_token")

      get "/api/v1/cart", headers: { "Authorization" => "Bearer #{access}" }
      expect(data["item_count"]).to eq(2)
      expect(Cart.exists?(token: guest_token)).to be false
    end

    it "sums quantities when the customer already has the same variant in their cart" do
      customer = create(:customer)
      variant = stocked_variant
      auth = ->(token) { { "Authorization" => "Bearer #{token}" } }

      post "/api/v1/customer/auth/login", params: { email: customer.email, password: "password123" }, as: :json
      access = response.parsed_body.dig("data", "tokens", "access_token")
      post "/api/v1/cart/items", params: { variant_id: variant.id, quantity: 1 }, headers: auth.call(access), as: :json

      post "/api/v1/cart/items", params: { variant_id: variant.id, quantity: 3 }, as: :json
      guest_token = data["token"]

      post "/api/v1/customer/auth/login",
           params: { email: customer.email, password: "password123" },
           headers: { "X-Cart-Token" => guest_token }, as: :json
      access2 = response.parsed_body.dig("data", "tokens", "access_token")

      get "/api/v1/cart", headers: auth.call(access2)
      expect(data["item_count"]).to eq(4)
    end
  end
end
