# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin permission management", type: :request do
  def sign_in_admin(admin, password = "password1234")
    post "/admin/login", params: { email: admin.email, password: password }
  end

  it "renders the edit form for a permission" do
    sign_in_admin(create(:admin_user, :super_admin, password: "password1234"))
    permission = create(:permission, key: "products.read", name: "View products")

    get "/admin/settings/permissions/#{permission.id}/edit"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("products.read")
  end

  it "updates the description and syncs role assignments" do
    sign_in_admin(create(:admin_user, :super_admin, password: "password1234"))
    permission = create(:permission)
    role = create(:role)

    patch "/admin/settings/permissions/#{permission.id}",
          params: { permission: { name: "Renamed", description: "New description" }, role_ids: [ role.id ] }

    permission.reload
    expect(permission.name).to eq("Renamed")
    expect(permission.description).to eq("New description")
    expect(permission.roles).to contain_exactly(role)
    expect(response).to redirect_to("/admin/settings/permissions")
  end

  it "removes a role assignment when unchecked" do
    sign_in_admin(create(:admin_user, :super_admin, password: "password1234"))
    permission = create(:permission)
    role = create(:role)
    permission.roles << role

    patch "/admin/settings/permissions/#{permission.id}",
          params: { permission: { name: permission.name }, role_ids: [ "" ] }

    expect(permission.reload.roles).to be_empty
  end

  it "never assigns a permission to the super_admin role" do
    sign_in_admin(create(:admin_user, :super_admin, password: "password1234"))
    permission = create(:permission)
    super_role = Role.find_or_create_by!(key: "super_admin") { |r| r.name = "Super Admin"; r.system = true }

    patch "/admin/settings/permissions/#{permission.id}",
          params: { permission: { name: permission.name }, role_ids: [ super_role.id ] }

    expect(permission.reload.roles).not_to include(super_role)
  end

  it "preserves an existing super_admin grant when editing role assignments" do
    sign_in_admin(create(:admin_user, :super_admin, password: "password1234"))
    permission = create(:permission)
    super_role = Role.find_or_create_by!(key: "super_admin") { |r| r.name = "Super Admin"; r.system = true }
    permission.roles << super_role
    role = create(:role)

    patch "/admin/settings/permissions/#{permission.id}",
          params: { permission: { name: permission.name }, role_ids: [ role.id ] }

    expect(permission.reload.roles).to contain_exactly(super_role, role)
  end

  it "forbids editing without permissions.manage" do
    reader = create(:role)
    reader.permissions << Permission.find_or_create_by!(key: "permissions.read") { |p| p.name = "View permissions" }
    admin = create(:admin_user, password: "password1234")
    admin.roles << reader
    sign_in_admin(admin)
    permission = create(:permission)

    patch "/admin/settings/permissions/#{permission.id}", params: { permission: { name: "Nope" } }

    expect(response).to redirect_to("/admin")
    expect(permission.reload.name).not_to eq("Nope")
  end
end
