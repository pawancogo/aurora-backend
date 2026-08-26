# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1 notifications", type: :request do
  def data
    response.parsed_body["data"]
  end

  def auth_headers_for(customer)
    post "/api/v1/customer/auth/login", params: { email: customer.email, password: "password123" }, as: :json
    access = response.parsed_body.dig("data", "tokens", "access_token")
    { "Authorization" => "Bearer #{access}" }
  end

  it "lists the signed-in customer's inbox with an unread count" do
    customer = create(:customer)
    create(:notification, customer: customer, title: "Yours")
    create(:notification, :read, customer: customer, event_key: "order.confirmed", title: "Read")
    create(:notification, title: "Someone else")

    get "/api/v1/notifications", headers: auth_headers_for(customer)

    expect(response).to have_http_status(:ok)
    expect(data.map { |row| row["title"] }).to include("Yours", "Read")
    expect(data.map { |row| row["title"] }).not_to include("Someone else")
    expect(response.parsed_body.dig("meta", "unread_count")).to eq(1)
  end

  it "marks one notification read and all unread as read" do
    customer = create(:customer)
    unread = create(:notification, customer: customer)
    other = create(:notification, customer: customer, event_key: "order.confirmed")
    auth = auth_headers_for(customer)

    patch "/api/v1/notifications/#{unread.id}/read", headers: auth, as: :json
    expect(response).to have_http_status(:ok)
    expect(data["read"]).to be true

    post "/api/v1/notifications/read_all", headers: auth, as: :json
    expect(response).to have_http_status(:ok)
    expect(other.reload).to be_read
    expect(customer.notifications.unread.count).to eq(0)
  end

  it "returns the unread badge count" do
    customer = create(:customer)
    create(:notification, customer: customer)
    create(:notification, :read, customer: customer, event_key: "order.shipped")

    get "/api/v1/notifications/unread_count", headers: auth_headers_for(customer)

    expect(response).to have_http_status(:ok)
    expect(data["unread_count"]).to eq(1)
  end

  it "requires authentication" do
    get "/api/v1/notifications"
    expect(response).to have_http_status(:unauthorized)
  end
end
