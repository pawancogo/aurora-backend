# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin orders", type: :request do
  def sign_in_admin(admin, password = "password1234")
    post "/admin/login", params: { email: admin.email, password: password }
  end

  it "lists orders for an admin with orders.read" do
    sign_in_admin(create(:admin_user, :super_admin, password: "password1234"))
    order = create(:order)

    get "/admin/orders"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(order.order_number)
  end

  it "shows an order with its items and shipping address" do
    sign_in_admin(create(:admin_user, :super_admin, password: "password1234"))
    order = create(:order)
    create(:order_item, order: order, product_name: "Aurora Tee")
    create(:order_address, order: order, full_name: "Jane Doe")

    get "/admin/orders/#{order.id}"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Aurora Tee")
    expect(response.body).to include("Jane Doe")
  end

  it "forbids access without orders.read" do
    sign_in_admin(create(:admin_user, password: "password1234"))

    get "/admin/orders"

    expect(response).to redirect_to("/admin")
  end
end
