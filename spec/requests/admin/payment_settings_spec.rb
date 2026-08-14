# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin payment settings", type: :request do
  def sign_in_admin(admin, password = "password1234")
    post "/admin/login", params: { email: admin.email, password: password }
  end

  it "shows the current Razorpay config id" do
    sign_in_admin(create(:admin_user, :super_admin, password: "password1234"))
    SiteSetting.create!(key: "razorpay.config_id", value: "cfg_live_123", value_type: "string", category: "payments")

    get "/admin/payment_settings"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("cfg_live_123")
  end

  it "updates the Razorpay config id, creating the setting if it doesn't exist yet" do
    sign_in_admin(create(:admin_user, :super_admin, password: "password1234"))

    patch "/admin/payment_settings", params: { razorpay_config_id: "cfg_live_456" }

    expect(response).to redirect_to(admin_payment_settings_path)
    expect(SiteSetting.get("razorpay.config_id")).to eq("cfg_live_456")
  end

  it "forbids access without settings.manage" do
    sign_in_admin(create(:admin_user, password: "password1234"))

    get "/admin/payment_settings"

    expect(response).to redirect_to("/admin")
  end
end
