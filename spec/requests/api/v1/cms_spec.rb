# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Public CMS API", type: :request do
  describe "GET /api/v1/homepage" do
    it "returns the live homepage sections with resolved data" do
      create(:homepage_section, :hero, position: 1)
      create(:banner, placement: "hero", title: "Slide")
      create(:product, new_arrival: true, name: "Fresh")
      create(:homepage_section, section_type: "product_rail", position: 2, config: { "source" => "new_arrival" })
      create(:homepage_section, :hidden, position: 3)

      get "/api/v1/homepage"

      expect(response).to have_http_status(:ok)
      sections = response.parsed_body["data"]["sections"]
      expect(sections.map { |s| s["type"] }).to eq(%w[hero product_rail])
      rail = sections.find { |s| s["type"] == "product_rail" }
      expect(rail["data"]["products"].map { |p| p["name"] }).to include("Fresh")
    end
  end

  describe "GET /api/v1/site" do
    it "returns the announcement and footer" do
      create(:banner, :announcement, title: "Sale")
      create(:footer_section, heading: "Company")

      get "/api/v1/site"

      data = response.parsed_body["data"]
      expect(data["announcement"]["title"]).to eq("Sale")
      expect(data["footer"].map { |f| f["heading"] }).to eq(%w[Company])
    end
  end

  describe "GET /api/v1/pages/:slug" do
    it "returns a published page" do
      create(:static_page, title: "About", slug: "about", body: "Hello", published: true)

      get "/api/v1/pages/about"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"]).to include("title" => "About", "body" => "Hello")
    end

    it "404s for an unpublished or unknown page" do
      create(:static_page, slug: "draft", published: false)
      get "/api/v1/pages/draft"
      expect(response).to have_http_status(:not_found)
      get "/api/v1/pages/nope"
      expect(response).to have_http_status(:not_found)
    end
  end
end
