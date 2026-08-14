# frozen_string_literal: true

# Every spec run gets a fake Razorpay auth (so Checkout::PlaceOrder's
# "payments not configured" guard doesn't fire) but Razorpay::Order.create
# is always stubbed — specs must never make a real network call to Razorpay.
RSpec.configure do |config|
  config.before do
    Razorpay.setup("rzp_test_stub", "stub_secret")
  end

  config.after(:suite) { Razorpay.auth = nil }
end

# Stubs Razorpay::Order.create to return a fake order with the given id,
# without touching the network. Call from a spec that exercises checkout.
def stub_razorpay_order(id: "order_TESTSTUB1")
  allow(Razorpay::Order).to receive(:create) do |options|
    Razorpay::Entity.new(
      "id" => id, "amount" => options[:amount], "currency" => options[:currency], "status" => "created"
    )
  end
end

# Stubs Razorpay::Refund.create the same way, for specs exercising Payments::Refund.
def stub_razorpay_refund(id: "rfnd_TESTSTUB1")
  allow(Razorpay::Refund).to receive(:create) do |options|
    Razorpay::Entity.new(
      "id" => id, "payment_id" => options[:payment_id], "amount" => options[:amount], "status" => "processed"
    )
  end
end
