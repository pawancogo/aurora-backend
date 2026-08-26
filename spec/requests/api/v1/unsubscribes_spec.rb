# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1 unsubscribe", type: :request do
  def data
    response.parsed_body["data"]
  end

  it "shows a masked email for a valid token without changing the preference" do
    customer = create(:customer, email: "ada@example.com", email_marketing: true)

    get "/api/v1/unsubscribe", params: { token: customer.unsubscribe_token }

    expect(response).to have_http_status(:ok)
    expect(data["email"]).to eq("a**@example.com")
    expect(data["email_marketing"]).to be true
    expect(customer.reload.email_marketing?).to be true
  end

  it "turns off marketing email on POST" do
    customer = create(:customer, email_marketing: true)

    post "/api/v1/unsubscribe", params: { token: customer.unsubscribe_token }, as: :json

    expect(response).to have_http_status(:ok)
    expect(data["email_marketing"]).to be false
    expect(customer.reload.email_marketing?).to be false
  end

  it "404s on a bad token" do
    get "/api/v1/unsubscribe", params: { token: "not-a-real-token" }
    expect(response).to have_http_status(:not_found)
  end
end
