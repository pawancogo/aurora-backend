# frozen_string_literal: true

require "rails_helper"

RSpec.describe Auth::AuthenticateCustomer do
  subject(:authenticate) { described_class.new(email: email, password: password).call }

  let(:customer) { create(:customer, password: "password123") }
  let(:email) { customer.email }
  let(:password) { "password123" }

  it "returns the customer for valid credentials" do
    expect(authenticate).to eq(customer)
  end

  context "with a wrong password" do
    let(:password) { "wrong-password" }

    it "raises an authentication error" do
      expect { authenticate }.to raise_error(described_class::AuthenticationError)
    end
  end

  context "with an unconfirmed customer" do
    let(:customer) { create(:customer, :unconfirmed, password: "password123") }

    it "raises an unconfirmed error" do
      expect { authenticate }.to raise_error(described_class::UnconfirmedError)
    end
  end

  context "with an inactive customer" do
    let(:customer) { create(:customer, :inactive, password: "password123") }

    it "raises an authentication error" do
      expect { authenticate }.to raise_error(described_class::AuthenticationError)
    end
  end
end
