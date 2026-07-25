# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin inventory", type: :request do
  def sign_in_admin(admin, password = "password1234")
    post "/admin/login", params: { email: admin.email, password: password }
  end

  let(:super_admin) { create(:admin_user, :super_admin, password: "password1234") }
  let(:variant) { create(:product_variant) }

  it "lists inventory" do
    sign_in_admin(super_admin)
    variant
    get "/admin/inventory"
    expect(response).to have_http_status(:ok)
  end

  it "adds stock via a delta and records a movement" do
    sign_in_admin(super_admin)

    expect do
      post "/admin/inventory/#{variant.id}/adjust", params: { mode: "add", quantity: "10", reason: "restock" }
    end.to change { variant.inventory_item.reload.on_hand }.by(10)
      .and change(StockMovement, :count).by(1)
    expect(StockMovement.last.admin_user).to eq(super_admin)
  end

  it "sets on-hand to an absolute value" do
    sign_in_admin(super_admin)
    variant.inventory_item.update!(on_hand: 3)

    post "/admin/inventory/#{variant.id}/adjust", params: { mode: "set", quantity: "20" }
    expect(variant.inventory_item.reload.on_hand).to eq(20)
  end

  it "updates threshold + backorder settings without a movement" do
    sign_in_admin(super_admin)

    expect do
      patch "/admin/inventory/#{variant.id}/settings",
            params: { inventory_item: { low_stock_threshold: "4", backorderable: "1" } }
    end.not_to change(StockMovement, :count)
    item = variant.inventory_item.reload
    expect(item.low_stock_threshold).to eq(4)
    expect(item.backorderable).to be(true)
  end

  it "filters to low stock" do
    sign_in_admin(super_admin)
    low = create(:product_variant)
    low.inventory_item.update!(on_hand: 1, low_stock_threshold: 5)

    get "/admin/inventory", params: { low_stock: 1 }
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(low.sku)
  end

  it "requires inventory.manage to adjust" do
    plain = create(:admin_user, password: "password1234")
    sign_in_admin(plain)

    expect do
      post "/admin/inventory/#{variant.id}/adjust", params: { mode: "add", quantity: "5", reason: "restock" }
    end.not_to change { variant.inventory_item.reload.on_hand }
  end
end
