# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin product relations", type: :request do
  def sign_in_admin(admin, password = "password1234")
    post "/admin/login", params: { email: admin.email, password: password }
  end

  let(:super_admin) { create(:admin_user, :super_admin, password: "password1234") }
  let(:product) { create(:product) }
  let(:other) { create(:product) }

  it "adds a related product" do
    sign_in_admin(super_admin)

    expect do
      post "/admin/products/#{product.id}/relations",
           params: { related_product_id: other.id, relation_kind: "recommended" }
    end.to change(ProductRelation, :count).by(1)
    expect(product.related_products).to include(other)
  end

  it "rejects a self-relation" do
    sign_in_admin(super_admin)

    expect do
      post "/admin/products/#{product.id}/relations", params: { related_product_id: product.id }
    end.not_to change(ProductRelation, :count)
  end

  it "removes a relation" do
    sign_in_admin(super_admin)
    relation = ProductRelation.create!(product: product, related_product: other, relation_kind: :related)

    expect do
      delete "/admin/products/#{product.id}/relations/#{relation.id}"
    end.to change(ProductRelation, :count).by(-1)
  end
end
