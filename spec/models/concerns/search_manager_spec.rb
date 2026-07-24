# frozen_string_literal: true

require "rails_helper"

# Exercised through Product, which declares:
#   search_manager on: %i[name sku search_keywords],
#                  aggs_on: %i[status brand_id category_id featured new_arrival best_seller],
#                  range_on: :price_cents
RSpec.describe SearchManager, type: :model do
  describe "Product.search" do
    it "matches the free-text term against the configured columns" do
      match = create(:product, name: "Aurora Runner")
      create(:product, name: "Zephyr Boot")

      result = Product.search({ q: "aurora" })

      expect(result.records).to contain_exactly(match)
    end

    it "filters by a facet column, mapping *_id values to integers" do
      brand = create(:brand)
      keep = create(:product, brand: brand)
      create(:product, brand: create(:brand))

      result = Product.search({ brand_id: brand.id.to_s })

      expect(result.records).to contain_exactly(keep)
    end

    it "finds a record by its numeric id" do
      target = create(:product, name: "Alpha")
      create(:product, name: "Beta")

      expect(Product.search({ q: target.id.to_s }).records.to_a).to include(target)
    end

    it "maps enum facet values (status keys) to their integer" do
      create(:product, status: :active)
      draft = create(:product, status: :draft)

      result = Product.search({ status: "draft" })

      expect(result.records).to contain_exactly(draft)
    end

    it "applies the numeric min/max range on the configured column" do
      create(:product, price_cents: 1_000)
      mid = create(:product, price_cents: 5_000)
      create(:product, price_cents: 20_000)

      result = Product.search({ min: "2000", max: "6000" })

      expect(result.records).to contain_exactly(mid)
    end

    it "builds facet counts with human-readable labels" do
      brand = create(:brand, name: "Nova")
      create(:product, brand: brand, status: :active)

      facets = Product.search({}).facets

      expect(facets.keys).to include("status", "brand_id", "featured")
      status_facet = facets["status"].find { |facet| facet[:value] == "active" }
      expect(status_facet[:label]).to eq("Active")
      brand_facet = facets["brand_id"].find { |facet| facet[:value] == brand.id.to_s }
      expect(brand_facet[:label]).to eq("Nova")
    end

    it "caps facet options to the limit but always keeps the selected value" do
      brands = Array.new(22) { create(:brand) }
      brands.each { |brand| create(:product, brand: brand) }

      capped = Product.search({}).facets["brand_id"]
      expect(capped.size).to eq(SearchManager::DEFAULT_FACET_LIMIT)

      target = brands.last
      selected = Product.search({ brand_id: target.id.to_s }).facets["brand_id"]
      expect(selected.map { |facet| facet[:value] }).to include(target.id.to_s)
    end

    it "keeps facets disjunctive — a facet ignores its own active filter" do
      brand_a = create(:brand)
      brand_b = create(:brand)
      create(:product, brand: brand_a)
      create(:product, brand: brand_b)

      result = Product.search({ brand_id: brand_a.id.to_s })

      # records are narrowed to brand A …
      expect(result.records.to_a.size).to eq(1)
      # … but the brand facet still lists both so the user can switch.
      expect(result.facets["brand_id"].map { |facet| facet[:value] }).to include(brand_a.id.to_s, brand_b.id.to_s)
    end

    context "pagination" do
      before { create_list(:product, 25) }

      it "paginates to the default page size" do
        records = Product.search({}).records
        expect(records.to_a.size).to eq(SearchManager::DEFAULT_PER_PAGE)
        expect(records.total_count).to eq(25)
        expect(records.total_pages).to eq(3)
      end

      it "honours the page and per_page params" do
        expect(Product.search({ per_page: "5" }).records.to_a.size).to eq(5)
        expect(Product.search({ page: "3" }).records.current_page).to eq(3)
      end

      it "caps per_page at the maximum" do
        expect(Product.search({ per_page: "9999" }).records.limit_value).to eq(SearchManager::MAX_PER_PAGE)
      end

      it "returns the whole relation when paginate: false" do
        expect(Product.search({}, paginate: false).records.count).to eq(25)
      end
    end
  end
end
