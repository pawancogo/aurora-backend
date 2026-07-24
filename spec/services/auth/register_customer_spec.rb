# frozen_string_literal: true

require "rails_helper"

RSpec.describe Auth::RegisterCustomer do
  let(:params) { { email: "New@Example.com", password: "password123", first_name: "New" } }

  it "creates an unconfirmed customer with a normalized email" do
    result = described_class.new(params).call

    expect(result.customer).to be_persisted
    expect(result.customer.email).to eq("new@example.com")
    expect(result.customer.confirmed?).to be(false)
  end

  it "stores only the digest of the confirmation token" do
    result = described_class.new(params).call

    expect(result.confirmation_token).to be_present
    expect(result.customer.confirmation_token_digest).to eq(TokenDigest.digest(result.confirmation_token))
  end

  it "enqueues a verification email" do
    expect { described_class.new(params).call }
      .to have_enqueued_mail(CustomerMailer, :verification_email)
  end
end
