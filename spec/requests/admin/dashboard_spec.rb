# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin dashboard and activity", type: :request do
  def sign_in_admin(admin, password = "password1234")
    post "/admin/login", params: { email: admin.email, password: password }
  end

  let(:super_admin) { create(:admin_user, :super_admin, password: "password1234") }

  it "renders ops metrics and saved queues" do
    sign_in_admin(super_admin)
    create(:order, placed_at: Time.current)

    get "/admin"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Orders today")
    expect(response.body).to include("Open fulfillment")
    expect(response.body).to include("Saved queues")
    expect(response.body).to include("Recent activity")
  end

  it "lists staff activity after a catalog edit" do
    sign_in_admin(super_admin)
    product = create(:product, name: "Old Lamp")

    patch "/admin/products/#{product.id}", params: {
      product: { name: "Renamed Lamp", sku: product.sku }
    }

    get "/admin/activity"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Renamed Lamp")
    expect(response.body).to include("updated")
  end
end
