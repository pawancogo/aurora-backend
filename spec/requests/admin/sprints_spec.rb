# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin sprints", type: :request do
  def sign_in_admin(admin, password = "password1234")
    post "/admin/login", params: { email: admin.email, password: password }
  end

  def admin_with(*permission_keys)
    admin = create(:admin_user, password: "password1234")
    role = create(:role)
    role.permissions = permission_keys.map { |key| Permission.find_or_create_by!(key: key) { |p| p.name = key } }
    admin.roles << role
    admin
  end

  it "lists sprints, expanded with their features, for an admin with roadmap.read" do
    sign_in_admin(admin_with("roadmap.read"))
    sprint = create(:sprint, title: "Cart & Wishlist")
    feature = create(:sprint_feature, sprint: sprint, title: "Wishlist toggle")

    get "/admin/sprints"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Cart &amp; Wishlist")
    expect(response.body).to include(feature.title)
  end

  it "forbids access without roadmap.read" do
    sign_in_admin(admin_with)

    get "/admin/sprints"

    expect(response).to redirect_to("/admin")
  end

  it "creates a sprint for an admin with roadmap.manage" do
    sign_in_admin(admin_with("roadmap.read", "roadmap.manage"))

    post "/admin/sprints", params: { sprint: { number: 20, title: "Payments", status: "planned" } }

    expect(Sprint.find_by(number: 20)).to be_present
    expect(response).to redirect_to(%r{/admin/sprints})
  end

  it "forbids creating a sprint without roadmap.manage" do
    sign_in_admin(admin_with("roadmap.read"))

    post "/admin/sprints", params: { sprint: { number: 20, title: "Payments" } }

    expect(Sprint.find_by(number: 20)).to be_nil
    expect(response).to redirect_to("/admin")
  end

  it "deletes a sprint and its features" do
    sign_in_admin(admin_with("roadmap.read", "roadmap.manage"))
    sprint = create(:sprint)
    create(:sprint_feature, sprint: sprint)

    expect { delete "/admin/sprints/#{sprint.id}" }.to change(Sprint, :count).by(-1).and change(SprintFeature, :count).by(-1)
  end
end
