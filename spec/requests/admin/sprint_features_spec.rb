# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin sprint features", type: :request do
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

  it "adds a feature to a sprint" do
    sign_in_admin(admin_with("roadmap.read", "roadmap.manage"))
    sprint = create(:sprint)

    post "/admin/sprints/#{sprint.id}/features",
      params: { sprint_feature: { area: "frontend", title: "Mini-cart",
                                   description: "<p>Quick view of the cart.</p>",
                                   technical_description: "<p>Popover.</p>" } }

    feature = sprint.sprint_features.find_by(title: "Mini-cart")
    expect(feature).to be_present
    expect(feature.description).to eq("<p>Quick view of the cart.</p>")
    expect(feature.technical_description).to eq("<p>Popover.</p>")
    expect(response).to redirect_to(%r{/admin/sprints#sprint-#{sprint.id}})
  end

  it "forbids adding a feature without roadmap.manage" do
    sign_in_admin(admin_with("roadmap.read"))
    sprint = create(:sprint)

    post "/admin/sprints/#{sprint.id}/features",
      params: { sprint_feature: { area: "frontend", title: "Mini-cart" } }

    expect(sprint.sprint_features.count).to eq(0)
    expect(response).to redirect_to("/admin")
  end

  it "updates and deletes a feature" do
    sign_in_admin(admin_with("roadmap.read", "roadmap.manage"))
    sprint = create(:sprint)
    feature = create(:sprint_feature, sprint: sprint, title: "Old title")

    patch "/admin/sprints/#{sprint.id}/features/#{feature.id}", params: { sprint_feature: { title: "New title" } }
    expect(feature.reload.title).to eq("New title")

    expect { delete "/admin/sprints/#{sprint.id}/features/#{feature.id}" }.to change(SprintFeature, :count).by(-1)
  end
end
