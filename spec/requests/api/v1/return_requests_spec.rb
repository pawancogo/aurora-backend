# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::ReturnRequests" do
  def data
    response.parsed_body["data"]
  end

  def auth_headers_for(customer)
    post "/api/v1/customer/auth/login", params: { email: customer.email, password: "password123" }, as: :json
    access = response.parsed_body.dig("data", "tokens", "access_token")
    { "Authorization" => "Bearer #{access}" }
  end

  def delivered_order_for(customer)
    order = create(:order, customer: customer, status: :delivered)
    create(:order_item, order: order)
    order
  end

  it "creates a return on a delivered order" do
    customer = create(:customer)
    order = delivered_order_for(customer)

    post "/api/v1/orders/#{order.id}/return_requests",
         params: { reason: "Damaged or defective", resolution: "refund" },
         headers: auth_headers_for(customer), as: :json

    expect(response).to have_http_status(:created)
    expect(data["status"]).to eq("requested")
    expect(data["rma_number"]).to start_with("RMA-")
    expect(data["items"].length).to eq(1)
  end

  it "lists only the signed-in customer's returns" do
    customer = create(:customer)
    other = create(:customer)
    mine = create(:return_request, order: create(:order, customer: customer, status: :delivered), customer: customer)
    create(:return_request, order: create(:order, customer: other, status: :delivered), customer: other)

    get "/api/v1/return_requests", headers: auth_headers_for(customer)

    expect(data.map { |row| row["id"] }).to eq([ mine.id ])
  end

  it "404s on another customer's return" do
    customer = create(:customer)
    other = create(:customer)
    theirs = create(:return_request, order: create(:order, customer: other, status: :delivered), customer: other)

    get "/api/v1/return_requests/#{theirs.id}", headers: auth_headers_for(customer)
    expect(response).to have_http_status(:not_found)
  end

  it "rejects a return on a shipped order" do
    customer = create(:customer)
    order = create(:order, customer: customer, status: :shipped)
    create(:order_item, order: order)

    post "/api/v1/orders/#{order.id}/return_requests",
         params: { reason: "Changed my mind" },
         headers: auth_headers_for(customer), as: :json

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body.dig("error", "code")).to eq("return_not_allowed")
  end
end
