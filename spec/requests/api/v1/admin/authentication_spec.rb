# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin authentication", type: :request do
  def login(admin, password)
    post "/api/v1/admin/auth/login", params: { email: admin.email, password: password }, as: :json
    response.parsed_body.dig("data", "tokens", "access_token")
  end

  it "logs in and returns roles and permissions" do
    admin = create(:admin_user, :super_admin, password: "password1234")

    post "/api/v1/admin/auth/login",
         params: { email: admin.email, password: "password1234" }, as: :json

    expect(response).to have_http_status(:ok)
    body = response.parsed_body
    expect(body.dig("data", "admin_user", "roles")).to include("super_admin")
    expect(body.dig("data", "tokens", "access_token")).to be_present
  end

  it "rejects a customer access token on admin endpoints" do
    customer = create(:customer)
    tokens = Auth::IssueTokenPair.new(customer).call

    get "/api/v1/admin/auth/me", headers: { "Authorization" => "Bearer #{tokens.access_token}" }

    expect(response).to have_http_status(:unauthorized)
  end

  describe "RBAC on GET /api/v1/admin/roles" do
    it "allows an admin holding roles.read" do
      permission = Permission.find_or_create_by!(key: "roles.read") { |p| p.name = "View roles" }
      role = create(:role)
      role.permissions << permission
      admin = create(:admin_user, password: "password1234")
      admin.roles << role

      get "/api/v1/admin/roles", headers: { "Authorization" => "Bearer #{login(admin, 'password1234')}" }

      expect(response).to have_http_status(:ok)
    end

    it "forbids an admin lacking roles.read" do
      admin = create(:admin_user, password: "password1234")

      get "/api/v1/admin/roles", headers: { "Authorization" => "Bearer #{login(admin, 'password1234')}" }

      expect(response).to have_http_status(:forbidden)
      expect(response.parsed_body.dig("error", "code")).to eq("forbidden")
    end
  end
end
