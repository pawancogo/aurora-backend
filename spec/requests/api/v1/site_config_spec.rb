# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1 site config", type: :request do
  describe "GET /api/v1/settings" do
    it "returns only publicly-readable settings as a map" do
      create(:site_setting, key: "site.name", value: "Aurora", public_read: true)
      create(:site_setting, key: "secret.key", value: "hidden", public_read: false)

      get "/api/v1/settings"

      expect(response).to have_http_status(:ok)
      data = response.parsed_body["data"]
      expect(data).to include("site.name" => "Aurora")
      expect(data).not_to have_key("secret.key")
    end
  end

  describe "GET /api/v1/feature_flags" do
    it "returns flags as a { key => enabled } map" do
      create(:feature_flag, key: "wishlist", enabled: true)
      create(:feature_flag, key: "promo_banner", enabled: false)

      get "/api/v1/feature_flags"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"]).to include("wishlist" => true, "promo_banner" => false)
    end
  end
end
