# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Customer authentication", type: :request do
  describe "registration → verification → login lifecycle" do
    it "walks the full flow" do
      post "/api/v1/customer/auth/register",
           params: { customer: { email: "jane@example.com", password: "password123", first_name: "Jane" } },
           as: :json
      expect(response).to have_http_status(:created)

      customer = Customer.find_by(email: "jane@example.com")
      expect(customer.confirmed?).to be(false)

      # Login is blocked until the email is verified.
      post "/api/v1/customer/auth/login",
           params: { email: "jane@example.com", password: "password123" }, as: :json
      expect(response).to have_http_status(:forbidden)
      expect(response.parsed_body.dig("error", "code")).to eq("email_unconfirmed")

      # Verify (using the service to obtain the raw token) auto-logs the customer in.
      token = Auth::ResendVerification.new(email: "jane@example.com").call
      post "/api/v1/customer/auth/verify-email", params: { token: token }, as: :json
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.dig("data", "tokens", "access_token")).to be_present
      expect(customer.reload.confirmed?).to be(true)

      # Login now succeeds.
      post "/api/v1/customer/auth/login",
           params: { email: "jane@example.com", password: "password123" }, as: :json
      expect(response).to have_http_status(:ok)
      access = response.parsed_body.dig("data", "tokens", "access_token")

      # Authenticated /me.
      get "/api/v1/customer/auth/me", headers: { "Authorization" => "Bearer #{access}" }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.dig("data", "customer", "email")).to eq("jane@example.com")

      # Unauthenticated /me is rejected.
      get "/api/v1/customer/auth/me"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "refresh + logout" do
    let(:customer) { create(:customer, password: "password123") }

    it "rotates refresh tokens and revokes on logout" do
      post "/api/v1/customer/auth/login",
           params: { email: customer.email, password: "password123" }, as: :json
      refresh = response.parsed_body.dig("data", "tokens", "refresh_token")

      post "/api/v1/customer/auth/refresh", params: { refresh_token: refresh }, as: :json
      expect(response).to have_http_status(:ok)
      new_refresh = response.parsed_body.dig("data", "tokens", "refresh_token")
      expect(new_refresh).not_to eq(refresh)

      # Old refresh token is now invalid.
      post "/api/v1/customer/auth/refresh", params: { refresh_token: refresh }, as: :json
      expect(response).to have_http_status(:unauthorized)

      # Logout revokes the current refresh token.
      post "/api/v1/customer/auth/logout", params: { refresh_token: new_refresh }, as: :json
      expect(response).to have_http_status(:ok)
      post "/api/v1/customer/auth/refresh", params: { refresh_token: new_refresh }, as: :json
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "password reset" do
    let(:customer) { create(:customer, password: "password123") }

    it "always responds success to forgot-password (enumeration-safe)" do
      post "/api/v1/customer/auth/forgot-password", params: { email: "nobody@example.com" }, as: :json
      expect(response).to have_http_status(:ok)
    end

    it "resets the password with a valid token" do
      token = Auth::RequestPasswordReset.new(email: customer.email).call

      post "/api/v1/customer/auth/reset-password",
           params: { token: token, password: "newpassword1" }, as: :json
      expect(response).to have_http_status(:ok)

      post "/api/v1/customer/auth/login",
           params: { email: customer.email, password: "newpassword1" }, as: :json
      expect(response).to have_http_status(:ok)
    end
  end
end
