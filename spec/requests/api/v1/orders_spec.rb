# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Orders" do
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
    get "/api/v1/orders"
    expect(response).to have_http_status(:unauthorized)
  end

  it "scopes order history to the signed-in customer" do
    customer_a = create(:customer)
    customer_b = create(:customer)
    order_a = create(:order, customer: customer_a)
    create(:order, customer: customer_b)

    get "/api/v1/orders", headers: auth_headers_for(customer_a)
    expect(data.map { |o| o["id"] }).to eq([ order_a.id ])
  end

  it "404s on another customer's order" do
    customer_a = create(:customer)
    customer_b = create(:customer)
    order_b = create(:order, customer: customer_b)

    get "/api/v1/orders/#{order_b.id}", headers: auth_headers_for(customer_a)
    expect(response).to have_http_status(:not_found)
  end

  it "paginates order history" do
    customer = create(:customer)
    create_list(:order, 15, customer: customer)

    get "/api/v1/orders", params: { per_page: 10 }, headers: auth_headers_for(customer)
    expect(data.length).to eq(10)
    expect(meta).to include("current_page" => 1, "per_page" => 10, "total_pages" => 2, "total_count" => 15)
  end

  describe "POST /api/v1/orders/:id/cancel" do
    it "cancels a cancellable order" do
      customer = create(:customer)
      order = create(:order, customer: customer, status: :confirmed)

      post "/api/v1/orders/#{order.id}/cancel", headers: auth_headers_for(customer)

      expect(response).to have_http_status(:ok)
      expect(data["status"]).to eq("cancelled")
      expect(order.reload).to be_cancelled
    end

    it "rejects cancelling an order that's already moved past confirmed" do
      customer = create(:customer)
      order = create(:order, customer: customer, status: :accepted)

      post "/api/v1/orders/#{order.id}/cancel", headers: auth_headers_for(customer)

      expect(response).to have_http_status(:unprocessable_content)
      expect(order.reload).to be_accepted
    end

    it "404s on another customer's order" do
      customer_a = create(:customer)
      customer_b = create(:customer)
      order_b = create(:order, customer: customer_b, status: :confirmed)

      post "/api/v1/orders/#{order_b.id}/cancel", headers: auth_headers_for(customer_a)

      expect(response).to have_http_status(:not_found)
    end
  end
end
