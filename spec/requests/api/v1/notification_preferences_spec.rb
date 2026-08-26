# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1 notification preferences", type: :request do
  def data
    response.parsed_body["data"]
  end

  def auth_headers_for(customer)
    post "/api/v1/customer/auth/login", params: { email: customer.email, password: "password123" }, as: :json
    access = response.parsed_body.dig("data", "tokens", "access_token")
    { "Authorization" => "Bearer #{access}" }
  end

  it "returns the catalog with current toggles" do
    customer = create(:customer)

    get "/api/v1/notification_preferences", headers: auth_headers_for(customer)

    expect(response).to have_http_status(:ok)
    expect(data["email_marketing"]).to be true
    review = data["events"].find { |event| event["event_key"] == "review.request" }
    expect(review["transactional"]).to be false
    placed = data["events"].find { |event| event["event_key"] == "order.placed" }
    expect(placed["channels"].find { |channel| channel["channel"] == "email" }["locked"]).to be true
  end

  it "lets a shopper turn off optional email but not transactional email" do
    customer = create(:customer)
    auth = auth_headers_for(customer)

    patch "/api/v1/notification_preferences",
          params: {
            email_marketing: false,
            preferences: [ { event_key: "review.request", channel: "email", enabled: false } ]
          },
          headers: auth, as: :json

    expect(response).to have_http_status(:ok)
    expect(data["email_marketing"]).to be false
    expect(customer.reload.email_marketing?).to be false

    patch "/api/v1/notification_preferences",
          params: { preferences: [ { event_key: "order.placed", channel: "email", enabled: false } ] },
          headers: auth, as: :json

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body.dig("error", "code")).to eq("invalid_preference")
  end
end
