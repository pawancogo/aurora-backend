# frozen_string_literal: true

require "rails_helper"

# The RailsAdmin data console mounted at /superadmin is Super-Admin-only and shares
# the admin portal's cookie session.
RSpec.describe "Super-admin data console (/superadmin)", type: :request do
  def sign_in_admin(admin, password = "password1234")
    post "/admin/login", params: { email: admin.email, password: password }
  end

  it "redirects an unauthenticated visitor to the admin login" do
    get "/superadmin"
    expect(response).to redirect_to("/admin/login")
  end

  it "forbids an authenticated non-super admin (back to the portal)" do
    admin = create(:admin_user, password: "password1234") # no roles → not super
    sign_in_admin(admin)

    get "/superadmin"

    expect(response).to redirect_to("/admin")
  end

  it "admits a super admin" do
    sign_in_admin(create(:admin_user, :super_admin, password: "password1234"))

    get "/superadmin"

    expect(response).to have_http_status(:ok)
  end
end
