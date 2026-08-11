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

  it "places an order from the cart: snapshots items/address, reserves stock, clears the cart, starts a payment" do
    stub_razorpay_order(id: "order_ABC123")
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
    expect(data["status"]).to eq("pending")
    expect(data["items"].length).to eq(1)
    expect(data["items"].first["quantity"]).to eq(2)
    expect(data["shipping_address"]["full_name"]).to eq("Jane Doe")
    expect(data["shipping"]).to eq(50.0)
    expect(data["total"]).to eq(data["subtotal"] + 50.0)
    expect(data["payment"]["razorpay_order_id"]).to eq("order_ABC123")

    expect(variant.inventory_item.reload.on_hand).to eq(10)
    expect(variant.inventory_item.reload.reserved).to eq(2)

    get "/api/v1/cart", headers: auth
    expect(response.parsed_body.dig("data", "item_count")).to eq(0)
  end

  it "rejects checkout without payments configured" do
    Razorpay.auth = nil
    customer = create(:customer)
    auth = auth_headers_for(customer)
    variant = stocked_variant
    post "/api/v1/cart/items", params: { variant_id: variant.id, quantity: 1 }, headers: auth, as: :json

    post "/api/v1/checkout", params: { address: address }, headers: auth, as: :json

    expect(response).to have_http_status(:unprocessable_content)
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
    stub_razorpay_order
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

  describe "POST /api/v1/checkout/:order_id/verify_payment" do
    def signature_for(razorpay_order_id:, razorpay_payment_id:)
      data = "#{razorpay_order_id}|#{razorpay_payment_id}"
      OpenSSL::HMAC.hexdigest("SHA256", Razorpay.auth[:password], data)
    end

    def place_pending_order(customer, auth)
      stub_razorpay_order(id: "order_VERIFY1")
      variant = stocked_variant(on_hand: 10)
      post "/api/v1/cart/items", params: { variant_id: variant.id, quantity: 2 }, headers: auth, as: :json
      post "/api/v1/checkout", params: { address: address }, headers: auth, as: :json
      [ data["id"], variant ]
    end

    it "confirms the order and fulfils inventory on a valid signature" do
      customer = create(:customer)
      auth = auth_headers_for(customer)
      order_id, variant = place_pending_order(customer, auth)
      signature = signature_for(razorpay_order_id: "order_VERIFY1", razorpay_payment_id: "pay_OK1")

      post "/api/v1/checkout/#{order_id}/verify_payment",
           params: { razorpay_payment_id: "pay_OK1", razorpay_signature: signature }, headers: auth, as: :json

      expect(response).to have_http_status(:ok)
      expect(data["status"]).to eq("confirmed")
      expect(Payment.find_by(razorpay_order_id: "order_VERIFY1")).to be_captured
      expect(variant.inventory_item.reload.on_hand).to eq(8)
      expect(variant.inventory_item.reload.reserved).to eq(0)
    end

    it "fails the order and releases the reservation on an invalid signature" do
      customer = create(:customer)
      auth = auth_headers_for(customer)
      order_id, variant = place_pending_order(customer, auth)

      post "/api/v1/checkout/#{order_id}/verify_payment",
           params: { razorpay_payment_id: "pay_BAD1", razorpay_signature: "not-a-real-signature" },
           headers: auth, as: :json

      expect(response).to have_http_status(:ok)
      expect(data["status"]).to eq("payment_failed")
      expect(Payment.find_by(razorpay_order_id: "order_VERIFY1")).to be_failed
      expect(variant.inventory_item.reload.on_hand).to eq(10)
      expect(variant.inventory_item.reload.reserved).to eq(0)
    end

    it "lets the customer retry after a failed attempt, reusing the same payment row" do
      customer = create(:customer)
      auth = auth_headers_for(customer)
      order_id, variant = place_pending_order(customer, auth)

      post "/api/v1/checkout/#{order_id}/verify_payment",
           params: { razorpay_payment_id: "pay_BAD1", razorpay_signature: "nope" }, headers: auth, as: :json
      expect(data["status"]).to eq("payment_failed")

      signature = signature_for(razorpay_order_id: "order_VERIFY1", razorpay_payment_id: "pay_RETRY1")
      post "/api/v1/checkout/#{order_id}/verify_payment",
           params: { razorpay_payment_id: "pay_RETRY1", razorpay_signature: signature }, headers: auth, as: :json

      expect(response).to have_http_status(:ok)
      expect(data["status"]).to eq("confirmed")
      expect(Payment.where(razorpay_order_id: "order_VERIFY1").count).to eq(1)
      expect(Payment.find_by(razorpay_order_id: "order_VERIFY1")).to be_captured
      expect(variant.inventory_item.reload.on_hand).to eq(8)
    end

    it "won't let a customer verify payment on someone else's order" do
      owner = create(:customer)
      order_id, = place_pending_order(owner, auth_headers_for(owner))

      other_auth = auth_headers_for(create(:customer))
      post "/api/v1/checkout/#{order_id}/verify_payment",
           params: { razorpay_payment_id: "pay_X", razorpay_signature: "x" }, headers: other_auth, as: :json

      expect(response).to have_http_status(:not_found)
    end
  end
end
