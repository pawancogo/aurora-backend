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

  describe "PATCH /admin/orders/:id/advance" do
    it "advances an order one step through the fulfillment sequence" do
      sign_in_admin(create(:admin_user, :super_admin, password: "password1234"))
      order = create(:order, status: :confirmed)

      patch "/admin/orders/#{order.id}/advance"

      expect(response).to redirect_to(admin_order_path(order))
      expect(order.reload).to be_accepted
    end

    it "no-ops with an alert once there's no next status" do
      sign_in_admin(create(:admin_user, :super_admin, password: "password1234"))
      order = create(:order, status: :delivered)

      patch "/admin/orders/#{order.id}/advance"

      expect(order.reload).to be_delivered
      expect(flash[:alert]).to be_present
    end

    it "forbids advancing without orders.manage" do
      sign_in_admin(create(:admin_user, password: "password1234"))
      order = create(:order, status: :confirmed)

      patch "/admin/orders/#{order.id}/advance"

      expect(response).to redirect_to("/admin")
      expect(order.reload).to be_confirmed
    end
  end

  describe "PATCH /admin/orders/:id/cancel" do
    it "cancels/rejects an order staff have already accepted" do
      sign_in_admin(create(:admin_user, :super_admin, password: "password1234"))
      order = create(:order, status: :accepted)

      patch "/admin/orders/#{order.id}/cancel"

      expect(response).to redirect_to(admin_order_path(order))
      expect(order.reload).to be_cancelled
    end

    it "refuses to cancel an order that's already shipped" do
      sign_in_admin(create(:admin_user, :super_admin, password: "password1234"))
      order = create(:order, status: :shipped)

      patch "/admin/orders/#{order.id}/cancel"

      expect(order.reload).to be_shipped
      expect(flash[:alert]).to be_present
    end

    it "forbids cancelling without orders.manage" do
      sign_in_admin(create(:admin_user, password: "password1234"))
      order = create(:order, status: :confirmed)

      patch "/admin/orders/#{order.id}/cancel"

      expect(response).to redirect_to("/admin")
      expect(order.reload).to be_confirmed
    end
  end

  describe "PATCH /admin/orders/:id/refund" do
    it "manually refunds a payment left refund_pending by a cancellation" do
      stub_razorpay_refund(id: "rfnd_ABC123")
      sign_in_admin(create(:admin_user, :super_admin, password: "password1234"))
      order = create(:order, status: :cancelled)
      payment = create(:payment, order: order, status: :refund_pending, razorpay_payment_id: "pay_ABC123")

      patch "/admin/orders/#{order.id}/refund"

      expect(response).to redirect_to(admin_order_path(order))
      expect(payment.reload).to be_refunded
      expect(payment.razorpay_refund_id).to eq("rfnd_ABC123")
    end

    it "alerts instead of erroring when nothing is awaiting a refund" do
      sign_in_admin(create(:admin_user, :super_admin, password: "password1234"))
      order = create(:order, status: :confirmed)

      patch "/admin/orders/#{order.id}/refund"

      expect(response).to redirect_to(admin_order_path(order))
      expect(flash[:alert]).to match(/no refund is pending/i)
    end

    it "surfaces a Razorpay failure as a flash alert without changing the payment" do
      allow(Razorpay::Refund).to receive(:create).and_raise(Razorpay::Error)
      sign_in_admin(create(:admin_user, :super_admin, password: "password1234"))
      order = create(:order, status: :cancelled)
      payment = create(:payment, order: order, status: :refund_pending)

      patch "/admin/orders/#{order.id}/refund"

      expect(flash[:alert]).to match(/Razorpay refund failed/)
      expect(payment.reload).to be_refund_pending
    end

    it "requires payments.manage even for an admin with orders.manage" do
      admin = create(:admin_user, password: "password1234")
      role = create(:role)
      role.permissions << create(:permission, key: "orders.manage")
      admin.roles << role
      sign_in_admin(admin)
      order = create(:order, status: :cancelled)
      create(:payment, order: order, status: :refund_pending)

      patch "/admin/orders/#{order.id}/refund"

      expect(response).to redirect_to("/admin")
    end
  end

  describe "GET /admin/orders (inline advance button)" do
    it "shows a Mark as button for an order with a next status, for an admin with orders.manage" do
      sign_in_admin(create(:admin_user, :super_admin, password: "password1234"))
      order = create(:order, status: :confirmed)

      get "/admin/orders"

      expect(response.body).to include("Mark as Accepted")
      expect(response.body).to include(admin_advance_order_path(order))
    end

    it "omits the button once there's no next status" do
      sign_in_admin(create(:admin_user, :super_admin, password: "password1234"))
      create(:order, status: :delivered)

      get "/admin/orders"

      expect(response.body).not_to include("Mark as")
    end
  end
end
