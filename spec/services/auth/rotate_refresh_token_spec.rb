# frozen_string_literal: true

require "rails_helper"

RSpec.describe Auth::RotateRefreshToken do
  let(:customer) { create(:customer) }
  let(:original) { Auth::IssueTokenPair.new(customer).call }

  it "issues a new pair and revokes the presented token" do
    rotation = described_class.new(original.refresh_token, owner_class: Customer).call

    expect(rotation.owner).to eq(customer)
    expect(rotation.tokens.refresh_token).to be_present
    expect(rotation.tokens.refresh_token).not_to eq(original.refresh_token)
  end

  it "rejects reuse of an already-rotated token" do
    described_class.new(original.refresh_token, owner_class: Customer).call

    expect { described_class.new(original.refresh_token, owner_class: Customer).call }
      .to raise_error(described_class::InvalidToken)
  end

  it "rejects an unknown token" do
    expect { described_class.new("does-not-exist", owner_class: Customer).call }
      .to raise_error(described_class::InvalidToken)
  end

  it "does not accept a customer token when rotating for an admin" do
    expect { described_class.new(original.refresh_token, owner_class: AdminUser).call }
      .to raise_error(described_class::InvalidToken)
  end
end
