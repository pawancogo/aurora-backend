# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin general settings", type: :request do
  def sign_in_admin(admin, password = "password1234")
    post "/admin/login", params: { email: admin.email, password: password }
  end

  it "shows the current general settings" do
    sign_in_admin(create(:admin_user, :super_admin, password: "password1234"))
    SiteSetting.create!(key: "site.support_email", value: "help@aurora.test", value_type: "string", category: "general")

    get "/admin/general_settings"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("help@aurora.test")
  end

  it "updates the general settings, creating any that don't exist yet" do
    sign_in_admin(create(:admin_user, :super_admin, password: "password1234"))

    patch "/admin/general_settings", params: {
      "site.name" => "Aurora", "site.tagline" => "New tagline", "site.support_email" => "care@aurora.test",
      "site.currency" => "INR"
    }

    expect(response).to redirect_to(admin_general_settings_path)
    expect(SiteSetting.get("site.support_email")).to eq("care@aurora.test")
    expect(SiteSetting.get("site.tagline")).to eq("New tagline")
  end

  it "forbids access without settings.manage" do
    sign_in_admin(create(:admin_user, password: "password1234"))

    get "/admin/general_settings"

    expect(response).to redirect_to("/admin")
  end
end
