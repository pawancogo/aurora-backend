# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin CMS management", type: :request do
  def sign_in_admin(admin, password = "password1234")
    post "/admin/login", params: { email: admin.email, password: password }
  end

  let(:super_admin) { create(:admin_user, :super_admin, password: "password1234") }

  describe "banners" do
    it "lists and creates a banner" do
      sign_in_admin(super_admin)
      get "/admin/banners"
      expect(response).to have_http_status(:ok)

      expect do
        post "/admin/banners", params: {
          banner: { placement: "hero", title: "Spring", image_url: "https://x/1.jpg", visible: "1" }
        }
      end.to change(Banner, :count).by(1)
      expect(response).to redirect_to("/admin/banners")
    end

    it "requires cms.manage to create" do
      sign_in_admin(create(:admin_user, password: "password1234"))
      expect do
        post "/admin/banners", params: { banner: { placement: "hero", title: "Nope" } }
      end.not_to change(Banner, :count)
    end
  end

  describe "homepage sections" do
    it "creates a section, keeping only recognised config keys" do
      sign_in_admin(super_admin)

      post "/admin/homepage-sections", params: {
        homepage_section: {
          section_type: "product_rail", title: "New In", position: "1", visible: "1",
          config: { source: "new_arrival", limit: "8", category_slug: "", body: "", placement: "" }
        }
      }

      section = HomepageSection.find_by(title: "New In")
      expect(section.section_type).to eq("product_rail")
      expect(section.config).to eq("source" => "new_arrival", "limit" => "8") # blanks dropped
    end
  end

  describe "static pages" do
    it "creates a page with a slug from the title" do
      sign_in_admin(super_admin)

      expect do
        post "/admin/pages", params: { static_page: { title: "About Us", body: "Hi", published: "1" } }
      end.to change(StaticPage, :count).by(1)
      expect(StaticPage.find_by(title: "About Us").slug).to eq("about-us")
    end
  end

  describe "footer sections" do
    it "creates a column, keeping only complete links" do
      sign_in_admin(super_admin)

      post "/admin/footer", params: {
        footer_section: {
          heading: "Company", visible: "1",
          links: { "0" => { label: "About", url: "/p/about" }, "1" => { label: "", url: "" } }
        }
      }

      section = FooterSection.find_by(heading: "Company")
      expect(section.links).to eq([ { "label" => "About", "url" => "/p/about" } ])
    end
  end
end
