# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin settings", type: :request do
  def sign_in_admin(admin, password = "password1234")
    post "/admin/login", params: { email: admin.email, password: password }
  end

  it "redirects /admin/settings to the roles tab" do
    sign_in_admin(create(:admin_user, :super_admin, password: "password1234"))

    get "/admin/settings"
    expect(response).to redirect_to("/admin/settings/roles")
  end

  it "renders the roles, permissions and team tabs" do
    sign_in_admin(create(:admin_user, :super_admin, password: "password1234"))

    get "/admin/settings/roles"
    expect(response).to have_http_status(:ok)
    get "/admin/settings/permissions"
    expect(response).to have_http_status(:ok)
    get "/admin/settings/team"
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("New admin") # management controls visible to super admin
  end

  it "assigns roles to another admin when the actor has users.manage" do
    sign_in_admin(create(:admin_user, :super_admin, password: "password1234"))
    target = create(:admin_user)
    role = create(:role)

    patch "/admin/settings/team/#{target.id}/roles", params: { role_ids: [ role.id ] }

    expect(response).to redirect_to("/admin/settings/team/#{target.id}")
    expect(target.reload.roles).to include(role)
  end

  it "forbids role assignment without users.manage" do
    reader_role = create(:role)
    reader_role.permissions << Permission.find_or_create_by!(key: "roles.read") { |p| p.name = "View roles" }
    admin = create(:admin_user, password: "password1234")
    admin.roles << reader_role
    sign_in_admin(admin)

    target = create(:admin_user)
    other = create(:role)
    patch "/admin/settings/team/#{target.id}/roles", params: { role_ids: [ other.id ] }

    expect(response).to redirect_to("/admin")
    expect(target.reload.roles).not_to include(other)
  end

  it "refuses to let an admin change their own roles" do
    super_admin = create(:admin_user, :super_admin, password: "password1234")
    sign_in_admin(super_admin)

    patch "/admin/settings/team/#{super_admin.id}/roles", params: { role_ids: [] }

    expect(response).to redirect_to("/admin/settings/team")
    expect(super_admin.reload.super_admin?).to be(true)
  end
end
