# frozen_string_literal: true

require "rails_helper"

RSpec.describe Payments::Refund do
  it "refunds a refund_pending payment via Razorpay and records the refund" do
    stub_razorpay_refund(id: "rfnd_ABC123")
    payment = create(:payment, status: :refund_pending, razorpay_payment_id: "pay_ABC123", amount_cents: 1500)

    result = described_class.new(payment: payment).call

    expect(result).to be_refunded
    expect(payment.reload).to be_refunded
    expect(payment.razorpay_refund_id).to eq("rfnd_ABC123")
    expect(payment.refunded_at).to be_present
    expect(Razorpay::Refund).to have_received(:create).with(payment_id: "pay_ABC123", amount: 1500)
  end

  it "raises without calling Razorpay when the payment isn't refund_pending" do
    stub_razorpay_refund
    payment = create(:payment, status: :captured)

    expect { described_class.new(payment: payment).call }.to raise_error(Payments::Refund::Error, /awaiting a refund/)
    expect(Razorpay::Refund).not_to have_received(:create)
    expect(payment.reload).to be_captured
  end

  it "wraps a Razorpay error without changing the payment" do
    payment = create(:payment, status: :refund_pending, razorpay_payment_id: "pay_ABC123")
    allow(Razorpay::Refund).to receive(:create).and_raise(Razorpay::Error)

    expect { described_class.new(payment: payment).call }.to raise_error(Payments::Refund::Error, /Razorpay refund failed/)
    expect(payment.reload).to be_refund_pending
  end
end
