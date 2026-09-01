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

  it "shows the shipment form for an order in fulfillment" do
    sign_in_admin(create(:admin_user, :super_admin, password: "password1234"))
    order = create(:order, status: :accepted)

    get "/admin/orders/#{order.id}"

    expect(response.body).to include("Carrier")
    expect(response.body).to include("Packing notes")
    expect(response.body).to include("Out for delivery")
  end

  it "forbids access without orders.read" do
    sign_in_admin(create(:admin_user, password: "password1234"))

    get "/admin/orders"

    expect(response).to redirect_to("/admin")
  end

  it "shows a refunded payment's refund id and date without crashing" do
    sign_in_admin(create(:admin_user, :super_admin, password: "password1234"))
    order = create(:order, status: :cancelled)
    create(:payment, order: order, status: :refunded, razorpay_refund_id: "rfnd_ABC123", refunded_at: Time.current)

    get "/admin/orders/#{order.id}"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("rfnd_ABC123")
  end

  it "doesn't crash on a refunded payment with no refund timestamp on record" do
    sign_in_admin(create(:admin_user, :super_admin, password: "password1234"))
    order = create(:order, status: :cancelled)
    create(:payment, order: order, status: :refunded, razorpay_refund_id: nil, refunded_at: nil)

    get "/admin/orders/#{order.id}"

    expect(response).to have_http_status(:ok)
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

    it "records a shipment event when advancing" do
      sign_in_admin(create(:admin_user, :super_admin, password: "password1234"))
      order = create(:order, status: :confirmed)

      patch "/admin/orders/#{order.id}/advance"

      expect(order.reload).to be_accepted
      expect(order.shipment.events.accepted).to be_present
    end

    it "saves optional delivery notes when marking delivered" do
      sign_in_admin(create(:admin_user, :super_admin, password: "password1234"))
      order = create(:order, status: :shipped)

      patch "/admin/orders/#{order.id}/advance", params: { delivery_notes: "Left with the guard" }

      expect(order.reload).to be_delivered
      expect(order.shipment.delivery_notes).to eq("Left with the guard")
      expect(order.delivery_events.last.description).to include("Left with the guard")
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

  describe "PATCH /admin/orders/:id/shipment" do
    it "saves carrier, tracking, and packing notes" do
      sign_in_admin(create(:admin_user, :super_admin, password: "password1234"))
      order = create(:order, status: :accepted)

      patch "/admin/orders/#{order.id}/shipment", params: {
        shipment: { carrier_name: "BlueDart", tracking_number: "AWB123", packing_notes: "Fragile" }
      }

      expect(response).to redirect_to(admin_order_path(order))
      shipment = order.reload.shipment
      expect(shipment.carrier_name).to eq("BlueDart")
      expect(shipment.tracking_number).to eq("AWB123")
      expect(shipment.packing_notes).to eq("Fragile")
    end

    it "rejects shipment edits on a pending order" do
      sign_in_admin(create(:admin_user, :super_admin, password: "password1234"))
      order = create(:order, status: :pending)

      patch "/admin/orders/#{order.id}/shipment", params: {
        shipment: { carrier_name: "BlueDart", tracking_number: "AWB123" }
      }

      expect(flash[:alert]).to match(/isn't in fulfillment/i)
      expect(order.reload.shipment).to be_nil
    end

    it "forbids editing a shipment without orders.manage" do
      sign_in_admin(create(:admin_user, password: "password1234"))
      order = create(:order, status: :accepted)

      patch "/admin/orders/#{order.id}/shipment", params: {
        shipment: { carrier_name: "BlueDart", tracking_number: "AWB123" }
      }

      expect(response).to redirect_to("/admin")
      expect(order.reload.shipment).to be_nil
    end
  end

  describe "POST /admin/orders/:id/shipment_events" do
    it "logs an out-for-delivery event" do
      sign_in_admin(create(:admin_user, :super_admin, password: "password1234"))
      order = create(:order, status: :shipped)

      post "/admin/orders/#{order.id}/shipment_events", params: { event_type: "out_for_delivery" }

      expect(response).to redirect_to(admin_order_path(order))
      event = order.reload.shipment.events.out_for_delivery.first
      expect(event.description).to eq("Out for delivery")
    end

    it "rejects an unknown event type" do
      sign_in_admin(create(:admin_user, :super_admin, password: "password1234"))
      order = create(:order, status: :shipped)

      post "/admin/orders/#{order.id}/shipment_events", params: { event_type: "lost" }

      expect(flash[:alert]).to match(/unknown event type/i)
      expect(order.reload.shipment).to be_nil
    end
  end

  it "walks the full manual delivery flow so the shopper sees carrier, tracking, and events" do
    sign_in_admin(create(:admin_user, :super_admin, password: "password1234"))
    customer = create(:customer)
    order = create(:order, customer: customer, status: :confirmed)
    create(:order_item, order: order)

    get "/admin/orders/#{order.id}"
    expect(response.body).to include("Carrier")
    expect(response.body).to include("Packing notes")

    patch "/admin/orders/#{order.id}/advance"
    expect(order.reload).to be_accepted

    patch "/admin/orders/#{order.id}/shipment", params: {
      shipment: { carrier_name: "BlueDart", tracking_number: "AWB123", packing_notes: "Fragile" }
    }
    follow_redirect!
    expect(response.body).to include("BlueDart")
    expect(response.body).to include("AWB123")
    expect(response.body).to include("Fragile")

    patch "/admin/orders/#{order.id}/advance" # ready_to_ship
    patch "/admin/orders/#{order.id}/advance" # shipped
    expect(order.reload).to be_shipped

    post "/admin/orders/#{order.id}/shipment_events", params: { event_type: "out_for_delivery" }
    patch "/admin/orders/#{order.id}/advance", params: { delivery_notes: "Handed to security" }
    expect(order.reload).to be_delivered

    post "/api/v1/customer/auth/login", params: { email: customer.email, password: "password123" }, as: :json
    token = response.parsed_body.dig("data", "tokens", "access_token")
    get "/api/v1/orders/#{order.id}", headers: { "Authorization" => "Bearer #{token}" }

    payload = response.parsed_body["data"]
    expect(payload["carrier_name"]).to eq("BlueDart")
    expect(payload["tracking_number"]).to eq("AWB123")
    expect(payload["events"].map { |event| event["description"] }).to include(
      "Accepted for fulfillment",
      "Tracking · BlueDart · AWB123",
      "Packed and ready to ship",
      "Shipped · BlueDart · AWB123",
      "Out for delivery",
      "Delivered — Handed to security"
    )
    expect(payload).not_to have_key("packing_notes")
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

    it "omits the advance button for a cancelled order, on both the list and detail pages" do
      sign_in_admin(create(:admin_user, :super_admin, password: "password1234"))
      order = create(:order, status: :cancelled)

      get "/admin/orders"
      expect(response.body).not_to include("Mark as")

      get "/admin/orders/#{order.id}"
      expect(response.body).not_to include("Mark as")

      patch "/admin/orders/#{order.id}/advance"
      expect(order.reload).to be_cancelled
    end

    it "shows a Refund pending chip on the list for a cancelled order awaiting refund" do
      sign_in_admin(create(:admin_user, :super_admin, password: "password1234"))
      order = create(:order, status: :cancelled)
      create(:payment, order: order, status: :refund_pending)
      other = create(:order, status: :confirmed)

      get "/admin/orders"

      order_row = response.body[/<tr>(?:(?!<\/tr>).)*#{order.order_number}.*?<\/tr>/m]
      other_row = response.body[/<tr>(?:(?!<\/tr>).)*#{other.order_number}.*?<\/tr>/m]
      expect(order_row).to include("Refund pending")
      expect(other_row).not_to include("Refund pending")
    end
  end

  describe "GET /admin/orders?refund_pending=1" do
    it "narrows the list to orders with a refund_pending payment" do
      sign_in_admin(create(:admin_user, :super_admin, password: "password1234"))
      needs_refund = create(:order, status: :cancelled)
      create(:payment, order: needs_refund, status: :refund_pending)
      already_refunded = create(:order, status: :cancelled)
      create(:payment, order: already_refunded, status: :refunded)
      unrelated = create(:order, status: :confirmed)

      get "/admin/orders", params: { refund_pending: "1" }

      expect(response.body).to include(needs_refund.order_number)
      expect(response.body).not_to include(already_refunded.order_number)
      expect(response.body).not_to include(unrelated.order_number)
    end

    it "narrows the list to orders that still need fulfillment" do
      sign_in_admin(create(:admin_user, :super_admin, password: "password1234"))
      open_order = create(:order, status: :confirmed)
      shipped = create(:order, status: :shipped)

      get "/admin/orders", params: { fulfillment: "1" }

      expect(response.body).to include(open_order.order_number)
      expect(response.body).not_to include(shipped.order_number)
    end
  end

  it "exports orders as CSV" do
    sign_in_admin(create(:admin_user, :super_admin, password: "password1234"))
    order = create(:order)

    get "/admin/orders/export"

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("text/csv")
    expect(response.body).to include(order.order_number)
  end
end
