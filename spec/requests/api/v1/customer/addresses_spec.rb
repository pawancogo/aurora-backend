# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Customer addresses", type: :request do
  def data
    response.parsed_body["data"]
  end

  def auth_headers_for(customer, password = "password123")
    post "/api/v1/customer/auth/login", params: { email: customer.email, password: password }, as: :json
    access = response.parsed_body.dig("data", "tokens", "access_token")
    { "Authorization" => "Bearer #{access}" }
  end

  let(:customer) { create(:customer, password: "password123") }

  it "requires authentication" do
    get "/api/v1/customer/addresses"
    expect(response).to have_http_status(:unauthorized)
  end

  it "lists only the signed-in customer's own addresses, default first" do
    mine = create(:address, customer: customer, full_name: "Mine")
    create(:address, customer: create(:customer), full_name: "Someone else's")
    mine.update!(is_default: true)

    get "/api/v1/customer/addresses", headers: auth_headers_for(customer)

    expect(response).to have_http_status(:ok)
    expect(data.map { |a| a["full_name"] }).to eq([ "Mine" ])
  end

  describe "POST /api/v1/customer/addresses" do
    it "creates an address and auto-defaults the first one" do
      post "/api/v1/customer/addresses",
           params: { address: {
             full_name: "Jane Doe", phone: "9999999999", line1: "123 Main St",
             city: "Mumbai", state: "Maharashtra", postal_code: "400001", country: "IN"
           } },
           headers: auth_headers_for(customer), as: :json

      expect(response).to have_http_status(:created)
      expect(data["is_default"]).to be(true)
      expect(customer.addresses.count).to eq(1)
    end

    it "does not auto-default a second address" do
      create(:address, customer: customer, is_default: true)

      post "/api/v1/customer/addresses",
           params: { address: {
             full_name: "Second", phone: "8888888888", line1: "456 Side St",
             city: "Pune", state: "Maharashtra", postal_code: "411001", country: "IN"
           } },
           headers: auth_headers_for(customer), as: :json

      expect(data["is_default"]).to be(false)
    end

    it "422s once the customer is at the configured address limit" do
      SiteSetting.create!(key: "addresses.max_per_customer", value: 1, value_type: "number", category: "general")
      create(:address, customer: customer)

      post "/api/v1/customer/addresses",
           params: { address: {
             full_name: "Second", phone: "8888888888", line1: "456 Side St",
             city: "Pune", state: "Maharashtra", postal_code: "411001", country: "IN"
           } },
           headers: auth_headers_for(customer), as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(customer.addresses.count).to eq(1)
    end
  end

  describe "PATCH /api/v1/customer/addresses/:id" do
    it "updates the customer's own address" do
      address = create(:address, customer: customer, full_name: "Old Name")

      patch "/api/v1/customer/addresses/#{address.id}",
            params: { address: { full_name: "New Name" } },
            headers: auth_headers_for(customer), as: :json

      expect(response).to have_http_status(:ok)
      expect(address.reload.full_name).to eq("New Name")
    end

    it "404s on another customer's address" do
      other_address = create(:address, customer: create(:customer))

      patch "/api/v1/customer/addresses/#{other_address.id}",
            params: { address: { full_name: "Hijacked" } },
            headers: auth_headers_for(customer), as: :json

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PATCH /api/v1/customer/addresses/:id/default" do
    it "demotes the previous default when a new one is set" do
      first = create(:address, customer: customer, is_default: true)
      second = create(:address, customer: customer, is_default: false)

      patch "/api/v1/customer/addresses/#{second.id}/default", headers: auth_headers_for(customer)

      expect(response).to have_http_status(:ok)
      expect(first.reload.is_default).to be(false)
      expect(second.reload.is_default).to be(true)
    end
  end

  describe "DELETE /api/v1/customer/addresses/:id" do
    it "deletes the customer's own address" do
      address = create(:address, customer: customer)

      delete "/api/v1/customer/addresses/#{address.id}", headers: auth_headers_for(customer)

      expect(response).to have_http_status(:ok)
      expect(Address.exists?(address.id)).to be(false)
    end

    it "404s on another customer's address" do
      other_address = create(:address, customer: create(:customer))

      delete "/api/v1/customer/addresses/#{other_address.id}", headers: auth_headers_for(customer)

      expect(response).to have_http_status(:not_found)
      expect(Address.exists?(other_address.id)).to be(true)
    end

    it "promotes another address to default when the default one is deleted" do
      default_address = create(:address, customer: customer, is_default: true)
      other = create(:address, customer: customer, is_default: false)

      delete "/api/v1/customer/addresses/#{default_address.id}", headers: auth_headers_for(customer)

      expect(other.reload.is_default).to be(true)
    end
  end
end
