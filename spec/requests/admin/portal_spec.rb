# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin portal", type: :request do
  it "redirects the backend root to /admin" do
    get "/"
    expect(response).to redirect_to("/admin")
  end

  it "redirects an unauthenticated /admin to the login page" do
    get "/admin"
    expect(response).to redirect_to("/admin/login")
  end

  it "renders the login page" do
    get "/admin/login"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Sign in")
  end

  it "signs in with valid credentials and lands on the dashboard" do
    admin = create(:admin_user, :super_admin, password: "password1234")

    post "/admin/login", params: { email: admin.email, password: "password1234" }
    expect(response).to redirect_to("/admin")

    follow_redirect!
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Dashboard")
  end

  it "rejects invalid credentials" do
    admin = create(:admin_user, password: "password1234")

    post "/admin/login", params: { email: admin.email, password: "wrong-password" }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Invalid email or password")
  end

  it "signs out and re-protects the dashboard" do
    admin = create(:admin_user, :super_admin, password: "password1234")
    post "/admin/login", params: { email: admin.email, password: "password1234" }

    delete "/admin/logout"
    expect(response).to redirect_to("/admin/login")

    get "/admin"
    expect(response).to redirect_to("/admin/login")
  end

  it "signs out via a form POST with _method override (as the button renders it)" do
    admin = create(:admin_user, :super_admin, password: "password1234")
    post "/admin/login", params: { email: admin.email, password: "password1234" }

    post "/admin/logout", params: { _method: "delete" }
    expect(response).to redirect_to("/admin/login")
  end
end
