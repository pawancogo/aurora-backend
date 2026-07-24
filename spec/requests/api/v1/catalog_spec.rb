# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1 catalog", type: :request do
  describe "GET /api/v1/products" do
    it "lists live products with pagination meta, excluding drafts" do
      create(:product, :with_image, name: "Alpha")
      create(:product, :draft, name: "Draft One")

      get "/api/v1/products"

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      names = body["data"].map { |p| p["name"] }
      expect(names).to include("Alpha")
      expect(names).not_to include("Draft One")
      expect(body["meta"]).to include("current_page", "total_count", "total_pages")
    end

    it "filters by category (including descendants)" do
      men = create(:category)
      topwear = create(:category, parent: men)
      included = create(:product, category: topwear)
      create(:product, category: create(:category))

      get "/api/v1/products", params: { category: men.slug }

      expect(response.parsed_body["data"].map { |p| p["id"] }).to eq([ included.id ])
    end
  end

  describe "GET /api/v1/products/:slug" do
    it "shows a live product" do
      product = create(:product, :with_image, name: "Shown Product")
      get "/api/v1/products/#{product.slug}"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.dig("data", "name")).to eq("Shown Product")
      expect(response.parsed_body.dig("data", "images").size).to eq(1)
    end

    it "returns 404 for a draft product" do
      product = create(:product, :draft)
      get "/api/v1/products/#{product.slug}"

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /api/v1/categories" do
    it "returns a nested, visible tree" do
      root = create(:category, name: "Root")
      create(:category, name: "Child", parent: root)
      create(:category, :hidden, name: "Hidden")

      get "/api/v1/categories"

      data = response.parsed_body["data"]
      names = data.map { |c| c["name"] }
      expect(names).to include("Root")
      expect(names).not_to include("Hidden")
      root_node = data.find { |c| c["name"] == "Root" }
      expect(root_node["children"].map { |c| c["name"] }).to eq([ "Child" ])
    end
  end

  describe "GET /api/v1/categories/:slug" do
    it "returns the category with a breadcrumb" do
      root = create(:category, name: "Men")
      sub = create(:category, name: "Shoes", parent: root)

      get "/api/v1/categories/#{sub.slug}"

      body = response.parsed_body["data"]
      expect(body.dig("category", "name")).to eq("Shoes")
      expect(body["breadcrumb"].map { |c| c["name"] }).to eq([ "Men" ])
    end
  end
end
