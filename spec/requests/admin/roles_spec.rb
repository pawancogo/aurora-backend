# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin role management", type: :request do
  def sign_in_admin(admin, password = "password1234")
    post "/admin/login", params: { email: admin.email, password: password }
  end

  it "creates a role with selected permissions (roles.manage)" do
    sign_in_admin(create(:admin_user, :super_admin, password: "password1234"))
    permission = create(:permission, key: "products.read")

    expect do
      post "/admin/settings/roles",
           params: { role: { name: "Catalog Viewer", key: "catalog_viewer", permission_ids: [ permission.id ] } }
    end.to change(Role, :count).by(1)

    role = Role.find_by(key: "catalog_viewer")
    expect(role.permissions).to include(permission)
    expect(response).to redirect_to("/admin/settings/roles")
  end

  it "replaces a role's permission set on update" do
    sign_in_admin(create(:admin_user, :super_admin, password: "password1234"))
    role = create(:role)
    old_permission = create(:permission)
    new_permission = create(:permission)
    role.permissions << old_permission

    patch "/admin/settings/roles/#{role.id}",
          params: { role: { name: role.name, permission_ids: [ new_permission.id ] } }

    expect(role.reload.permissions).to contain_exactly(new_permission)
  end

  it "deletes a non-system role" do
    sign_in_admin(create(:admin_user, :super_admin, password: "password1234"))
    role = create(:role)

    expect { delete "/admin/settings/roles/#{role.id}" }.to change(Role, :count).by(-1)
  end

  it "refuses to delete a system role" do
    sign_in_admin(create(:admin_user, :super_admin, password: "password1234"))
    role = create(:role, system: true)

    expect { delete "/admin/settings/roles/#{role.id}" }.not_to change(Role, :count)
    expect(response).to redirect_to("/admin/settings/roles")
  end

  it "forbids role management without roles.manage" do
    reader_role = create(:role)
    reader_role.permissions << Permission.find_or_create_by!(key: "roles.read") { |p| p.name = "View roles" }
    admin = create(:admin_user, password: "password1234")
    admin.roles << reader_role
    sign_in_admin(admin)

    expect do
      post "/admin/settings/roles", params: { role: { name: "Nope", key: "nope_role" } }
    end.not_to change(Role, :count)
    expect(response).to redirect_to("/admin")
  end
end
