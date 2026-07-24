# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin options typeahead", type: :request do
  def sign_in_admin(admin, password = "password1234")
    post "/admin/login", params: { email: admin.email, password: password }
  end

  it "returns matching records as value/label pairs" do
    sign_in_admin(create(:admin_user, :super_admin, password: "password1234"))
    match = create(:brand, name: "Nova Labs")
    create(:brand, name: "Zephyr")

    get "/admin/options/brands", params: { q: "nova" }

    expect(response).to have_http_status(:ok)
    labels = response.parsed_body["data"].map { |option| option["label"] }
    expect(labels).to include(match.name)
    expect(labels).not_to include("Zephyr")
  end

  it "excludes a given id (self-parent guard for categories)" do
    sign_in_admin(create(:admin_user, :super_admin, password: "password1234"))
    category = create(:category, name: "Self")

    get "/admin/options/categories", params: { exclude: category.id }

    expect(response.parsed_body["data"].map { |option| option["value"] }).not_to include(category.id)
  end

  it "404s an unknown resource" do
    sign_in_admin(create(:admin_user, :super_admin, password: "password1234"))

    get "/admin/options/widgets"

    expect(response).to have_http_status(:not_found)
  end

  it "forbids without the resource read permission" do
    sign_in_admin(create(:admin_user, password: "password1234"))

    get "/admin/options/brands"

    expect(response).to have_http_status(:forbidden)
  end
end
