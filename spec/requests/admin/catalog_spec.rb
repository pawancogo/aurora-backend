# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin catalog management", type: :request do
  def sign_in_admin(admin, password = "password1234")
    post "/admin/login", params: { email: admin.email, password: password }
  end

  let(:super_admin) { create(:admin_user, :super_admin, password: "password1234") }

  describe "categories" do
    it "lists categories" do
      sign_in_admin(super_admin)
      category = create(:category)

      get "/admin/categories"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(category.name)
    end

    it "creates a category" do
      sign_in_admin(super_admin)

      expect do
        post "/admin/categories", params: { category: { name: "Footwear", visible: "1" } }
      end.to change(Category, :count).by(1)

      expect(Category.find_by(name: "Footwear").slug).to eq("footwear")
      expect(response).to redirect_to("/admin/categories")
    end

    it "updates a category" do
      sign_in_admin(super_admin)
      category = create(:category)

      patch "/admin/categories/#{category.id}", params: { category: { name: "Renamed" } }

      expect(category.reload.name).to eq("Renamed")
    end

    it "soft-deletes a category" do
      sign_in_admin(super_admin)
      category = create(:category)

      expect { delete "/admin/categories/#{category.id}" }.to change { Category.kept.count }.by(-1)
      expect(category.reload.discarded?).to be(true)
    end
  end

  describe "brands" do
    it "creates a brand" do
      sign_in_admin(super_admin)

      expect do
        post "/admin/brands", params: { brand: { name: "Aurora Labs" } }
      end.to change(Brand, :count).by(1)
    end

    it "updates a brand" do
      sign_in_admin(super_admin)
      brand = create(:brand)

      patch "/admin/brands/#{brand.id}", params: { brand: { name: "Nova" } }

      expect(brand.reload.name).to eq("Nova")
    end
  end

  describe "products" do
    it "lists products" do
      sign_in_admin(super_admin)
      product = create(:product)

      get "/admin/products"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(product.name)
    end

    it "creates a product, converting rupees to cents and images" do
      sign_in_admin(super_admin)
      brand = create(:brand)

      expect do
        post "/admin/products", params: {
          product: {
            name: "Runner X", sku: "RUN-X-1", status: "active", brand_id: brand.id,
            price: "1299.50", mrp: "1999", currency: "INR",
            highlights_text: "Breathable\nLightweight",
            image_urls: "https://cdn.test/a.jpg\nhttps://cdn.test/b.jpg"
          }
        }
      end.to change(Product, :count).by(1)

      product = Product.find_by(sku: "RUN-X-1")
      expect(product.price_cents).to eq(129_950)
      expect(product.mrp_cents).to eq(199_900)
      expect(product.highlights).to eq(%w[Breathable Lightweight])
      expect(product.product_images.count).to eq(2)
      expect(product.product_images.first.primary).to be(true)
    end

    it "replaces images on update" do
      sign_in_admin(super_admin)
      product = create(:product, :with_image)

      patch "/admin/products/#{product.id}", params: {
        product: { name: product.name, sku: product.sku, image_urls: "https://cdn.test/new.jpg" }
      }

      expect(product.reload.product_images.pluck(:source_url)).to eq([ "https://cdn.test/new.jpg" ])
    end

    it "soft-deletes a product" do
      sign_in_admin(super_admin)
      product = create(:product)

      expect { delete "/admin/products/#{product.id}" }.to change { Product.kept.count }.by(-1)
    end
  end

  describe "permissions" do
    it "forbids catalog management without the manage permission" do
      reader = create(:role)
      reader.permissions << Permission.find_or_create_by!(key: "categories.read") { |p| p.name = "View categories" }
      admin = create(:admin_user, password: "password1234")
      admin.roles << reader
      sign_in_admin(admin)

      expect do
        post "/admin/categories", params: { category: { name: "Blocked" } }
      end.not_to change(Category, :count)
      expect(response).to redirect_to("/admin")
    end
  end
end
