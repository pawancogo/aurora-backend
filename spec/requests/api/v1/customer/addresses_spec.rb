# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Customer::Addresses" do
  def data
    response.parsed_body["data"]
  end

  def auth_headers_for(customer)
    post "/api/v1/customer/auth/login", params: { email: customer.email, password: "password123" }, as: :json
    access = response.parsed_body.dig("data", "tokens", "access_token")
    { "Authorization" => "Bearer #{access}" }
  end

  def address_payload(**overrides)
    {
      address: {
        address_type: "home",
        full_name: "Jane Doe",
        phone: "9999999999",
        line1: "123 Main St",
        city: "Mumbai",
        state: "Maharashtra",
        postal_code: "400001",
        country: "IN"
      }.merge(overrides)
    }
  end

  it "requires authentication" do
    get "/api/v1/customer/addresses"
    expect(response).to have_http_status(:unauthorized)
  end

  it "creates, lists, updates, sets default, and deletes an address" do
    customer = create(:customer)
    auth = auth_headers_for(customer)

    post "/api/v1/customer/addresses", params: address_payload, headers: auth, as: :json
    expect(response).to have_http_status(:created)
    expect(data["city"]).to eq("Mumbai")
    expect(data["is_default"]).to be(true)
    expect(data["address_type"]).to eq("home")
    first_id = data["id"]

    post "/api/v1/customer/addresses",
         params: address_payload(address_type: "office", line1: "456 Work Ave", full_name: "Jane Office"),
         headers: auth, as: :json
    expect(response).to have_http_status(:created)
    expect(data["is_default"]).to be(false)
    second_id = data["id"]

    get "/api/v1/customer/addresses", headers: auth
    expect(data.length).to eq(2)
    expect(data.first["id"]).to eq(first_id)

    patch "/api/v1/customer/addresses/#{first_id}",
          params: address_payload(city: "Pune"),
          headers: auth, as: :json
    expect(response).to have_http_status(:ok)
    expect(data["city"]).to eq("Pune")

    patch "/api/v1/customer/addresses/#{second_id}/default", headers: auth, as: :json
    expect(response).to have_http_status(:ok)
    expect(data["is_default"]).to be(true)

    get "/api/v1/customer/addresses", headers: auth
    defaults = data.select { |row| row["is_default"] }
    expect(defaults.length).to eq(1)
    expect(defaults.first["id"]).to eq(second_id)

    delete "/api/v1/customer/addresses/#{second_id}", headers: auth
    expect(response).to have_http_status(:ok)

    get "/api/v1/customer/addresses", headers: auth
    expect(data.length).to eq(1)
    expect(data.first["id"]).to eq(first_id)
    expect(data.first["is_default"]).to be(true)
  end

  it "scopes addresses to the signed-in customer" do
    owner = create(:customer)
    other = create(:customer)
    address = create(:address, customer: owner)

    get "/api/v1/customer/addresses", headers: auth_headers_for(other)
    expect(data).to eq([])

    patch "/api/v1/customer/addresses/#{address.id}",
          params: address_payload(city: "Stolen"),
          headers: auth_headers_for(other), as: :json
    expect(response).to have_http_status(:not_found)
  end

  it "rejects an invalid address" do
    customer = create(:customer)
    auth = auth_headers_for(customer)

    post "/api/v1/customer/addresses",
         params: address_payload(full_name: "", phone: "1"),
         headers: auth, as: :json

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body.dig("error", "code")).to eq("validation_failed")
  end
end
