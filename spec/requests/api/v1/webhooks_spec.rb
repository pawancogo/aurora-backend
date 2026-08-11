# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Webhooks" do
  let(:secret) { "whsec_test" }

  before { ENV["RAZORPAY_WEBHOOK_SECRET"] = secret }
  after { ENV.delete("RAZORPAY_WEBHOOK_SECRET") }

  def signed_post(payload)
    body = payload.to_json
    signature = OpenSSL::HMAC.hexdigest("SHA256", secret, body)
    post "/api/v1/webhooks/razorpay", params: body, headers: { "X-Razorpay-Signature" => signature, "Content-Type" => "application/json" }
  end

  def pending_order_with_reservation(quantity: 2, on_hand: 10)
    variant = create(:product_variant, :priced)
    variant.inventory_item.update!(on_hand: on_hand)
    Inventory::Reserve.new(inventory_item: variant.inventory_item, quantity: quantity).call

    order = create(:order, status: :pending)
    create(:order_item, order: order, product_variant: variant, quantity: quantity)
    payment = create(:payment, order: order, razorpay_order_id: "order_WH1")
    [ order, variant, payment ]
  end

  def capture_payload(razorpay_order_id, razorpay_payment_id)
    { event: "payment.captured",
      payload: { payment: { entity: { id: razorpay_payment_id, order_id: razorpay_order_id } } } }
  end

  def failed_payload(razorpay_order_id, razorpay_payment_id)
    { event: "payment.failed",
      payload: { payment: { entity: { id: razorpay_payment_id, order_id: razorpay_order_id } } } }
  end

  it "confirms the order and fulfils inventory on payment.captured" do
    order, variant, = pending_order_with_reservation

    signed_post(capture_payload("order_WH1", "pay_WH1"))

    expect(response).to have_http_status(:ok)
    expect(order.reload.status).to eq("confirmed")
    expect(Payment.find_by(razorpay_order_id: "order_WH1")).to be_captured
    expect(variant.inventory_item.reload.on_hand).to eq(8)
    expect(variant.inventory_item.reload.reserved).to eq(0)
  end

  it "fails the order and releases the reservation on payment.failed" do
    order, variant, = pending_order_with_reservation

    signed_post(failed_payload("order_WH1", "pay_WH1"))

    expect(response).to have_http_status(:ok)
    expect(order.reload.status).to eq("payment_failed")
    expect(variant.inventory_item.reload.on_hand).to eq(10)
    expect(variant.inventory_item.reload.reserved).to eq(0)
  end

  it "is idempotent — a repeat event for an already-captured payment does nothing" do
    order, variant, = pending_order_with_reservation
    signed_post(capture_payload("order_WH1", "pay_WH1"))

    signed_post(capture_payload("order_WH1", "pay_WH1"))

    expect(response).to have_http_status(:ok)
    expect(order.reload.status).to eq("confirmed")
    expect(variant.inventory_item.reload.on_hand).to eq(8)
  end

  it "rejects a request with an invalid signature" do
    pending_order_with_reservation
    post "/api/v1/webhooks/razorpay", params: capture_payload("order_WH1", "pay_WH1").to_json,
                                       headers: { "X-Razorpay-Signature" => "not-real", "Content-Type" => "application/json" }

    expect(response).to have_http_status(:bad_request)
  end

  it "rejects a request with no signature header" do
    post "/api/v1/webhooks/razorpay", params: capture_payload("order_WH1", "pay_WH1").to_json,
                                       headers: { "Content-Type" => "application/json" }

    expect(response).to have_http_status(:bad_request)
  end
end
