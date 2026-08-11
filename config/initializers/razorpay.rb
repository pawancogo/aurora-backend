# frozen_string_literal: true

# Configures the Razorpay SDK when credentials are present. Without them,
# Razorpay.auth stays nil — Checkout::PlaceOrder surfaces a clear error
# instead of the SDK raising deep inside an HTTP call.
if ENV["RAZORPAY_KEY_ID"].present? && ENV["RAZORPAY_KEY_SECRET"].present?
  Razorpay.setup(ENV["RAZORPAY_KEY_ID"], ENV["RAZORPAY_KEY_SECRET"])
end
