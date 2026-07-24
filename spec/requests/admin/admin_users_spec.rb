# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin user management", type: :request do
  def sign_in_admin(admin, password = "password1234")
    post "/admin/login", params: { email: admin.email, password: password }
  end

  it "renders the standalone new-admin form page" do
    sign_in_admin(create(:admin_user, :super_admin, password: "password1234"))
    create(:role, name: "Support")

    get "/admin/settings/team/new"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("New admin")
    expect(response.body).to include("Support")
  end

  it "re-renders the new-admin page with errors on invalid input" do
    sign_in_admin(create(:admin_user, :super_admin, password: "password1234"))

    post "/admin/settings/team", params: { admin_user: { email: "", password: "short" } }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("New admin")
  end

  it "creates an admin with roles (users.manage)" do
    sign_in_admin(create(:admin_user, :super_admin, password: "password1234"))
    role = create(:role)

    expect do
      post "/admin/settings/team",
           params: {
             admin_user: { email: "new@admin.test", first_name: "New", password: "password1234" },
             role_ids: [ role.id ]
           }
    end.to change(AdminUser, :count).by(1)

    created = AdminUser.find_by(email: "new@admin.test")
    expect(created.roles).to include(role)
  end

  it "deactivates another admin" do
    sign_in_admin(create(:admin_user, :super_admin, password: "password1234"))
    target = create(:admin_user)

    patch "/admin/settings/team/#{target.id}/status"

    expect(target.reload.status).to eq("inactive")
  end

  it "soft-deletes another admin" do
    sign_in_admin(create(:admin_user, :super_admin, password: "password1234"))
    target = create(:admin_user)

    delete "/admin/settings/team/#{target.id}"

    expect(target.reload.discarded?).to be(true)
  end

  it "forbids admin creation without users.manage" do
    reader = create(:role)
    reader.permissions << Permission.find_or_create_by!(key: "users.read") { |p| p.name = "View admins" }
    admin = create(:admin_user, password: "password1234")
    admin.roles << reader
    sign_in_admin(admin)

    expect do
      post "/admin/settings/team", params: { admin_user: { email: "x@admin.test", password: "password1234" } }
    end.not_to change(AdminUser, :count)
    expect(response).to redirect_to("/admin")
  end

  it "cannot deactivate its own account" do
    super_admin = create(:admin_user, :super_admin, password: "password1234")
    sign_in_admin(super_admin)

    patch "/admin/settings/team/#{super_admin.id}/status"

    expect(super_admin.reload.status).to eq("active")
  end

  it "shows an admin's detail with their login sessions" do
    sign_in_admin(create(:admin_user, :super_admin, password: "password1234"))
    target = create(:admin_user, email: "team.member@admin.test")
    Auth::IssueTokenPair.new(target).call

    get "/admin/settings/team/#{target.id}"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Login sessions")
    expect(response.body).to include("team.member@admin.test")
  end

  it "revokes a single admin session" do
    sign_in_admin(create(:admin_user, :super_admin, password: "password1234"))
    target = create(:admin_user)
    Auth::IssueTokenPair.new(target).call
    session = target.refresh_tokens.first

    delete "/admin/settings/team/#{target.id}/sessions/#{session.id}"

    expect(session.reload.revoked_at).to be_present
    expect(response).to redirect_to("/admin/settings/team/#{target.id}")
  end

  it "revokes all active admin sessions" do
    sign_in_admin(create(:admin_user, :super_admin, password: "password1234"))
    target = create(:admin_user)
    Auth::IssueTokenPair.new(target).call

    delete "/admin/settings/team/#{target.id}/sessions"

    expect(target.refresh_tokens.active.count).to eq(0)
  end

  it "forbids viewing admin detail without users.manage" do
    reader = create(:role)
    reader.permissions << Permission.find_or_create_by!(key: "users.read") { |p| p.name = "View admins" }
    admin = create(:admin_user, password: "password1234")
    admin.roles << reader
    sign_in_admin(admin)
    target = create(:admin_user)

    get "/admin/settings/team/#{target.id}"

    expect(response).to redirect_to("/admin")
  end
end
