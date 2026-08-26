# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin return requests", type: :request do
  def sign_in_admin(admin, password = "password1234")
    post "/admin/login", params: { email: admin.email, password: password }
  end

  it "lists return requests for an admin with orders.read" do
    sign_in_admin(create(:admin_user, :super_admin, password: "password1234"))
    request = create(:return_request)

    get "/admin/returns"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(request.rma_number)
  end

  it "approves, receives, and completes a refund RMA" do
    sign_in_admin(create(:admin_user, :super_admin, password: "password1234"))
    order = create(:order, status: :delivered)
    item = create(:order_item, order: order)
    item.product_variant.inventory_item.update!(on_hand: 1)
    create(:payment, order: order, status: :captured)
    rma = ReturnRequest.request!(order: order, reason: "Size doesn't fit")

    patch "/admin/returns/#{rma.id}/approve"
    expect(rma.reload).to be_approved

    patch "/admin/returns/#{rma.id}/receive"
    expect(rma.reload).to be_received
    expect(item.product_variant.inventory_item.reload.on_hand).to eq(3)

    patch "/admin/returns/#{rma.id}/complete"
    expect(rma.reload).to be_completed
    expect(order.reload).to be_returned
    expect(order.refund_pending?).to be true
  end

  it "rejects with a required note" do
    sign_in_admin(create(:admin_user, :super_admin, password: "password1234"))
    rma = create(:return_request)

    patch "/admin/returns/#{rma.id}/reject", params: { admin_notes: "" }
    expect(rma.reload).to be_requested
    expect(flash[:alert]).to match(/note/i)

    patch "/admin/returns/#{rma.id}/reject", params: { admin_notes: "Outside the window" }
    expect(rma.reload).to be_rejected
  end

  it "forbids the list without orders.read" do
    sign_in_admin(create(:admin_user, password: "password1234"))

    get "/admin/returns"

    expect(response).to redirect_to("/admin")
  end
end
