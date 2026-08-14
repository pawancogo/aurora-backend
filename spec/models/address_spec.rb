# frozen_string_literal: true

require "rails_helper"

RSpec.describe Address do
  it "requires the core address fields" do
    address = build(:address, full_name: nil, line1: nil)
    expect(address).not_to be_valid
    expect(address.errors.attribute_names).to include(:full_name, :line1)
  end

  describe "default exclusivity" do
    it "demotes the customer's other addresses when one is saved as default" do
      customer = create(:customer)
      first = create(:address, customer: customer, is_default: true)
      second = create(:address, customer: customer, is_default: false)

      second.update!(is_default: true)

      expect(first.reload.is_default).to be(false)
      expect(second.reload.is_default).to be(true)
    end

    it "leaves other addresses alone when a non-default address is saved" do
      customer = create(:customer)
      default_address = create(:address, customer: customer, is_default: true)
      other = create(:address, customer: customer, is_default: false)

      other.update!(full_name: "Renamed")

      expect(default_address.reload.is_default).to be(true)
    end
  end

  describe "#promote_next_default" do
    it "promotes the most recently updated remaining address after the default one is destroyed" do
      customer = create(:customer)
      default_address = create(:address, customer: customer, is_default: true)
      older = create(:address, customer: customer, is_default: false)
      newer = create(:address, customer: customer, is_default: false)

      default_address.destroy!

      expect(newer.reload.is_default).to be(true)
      expect(older.reload.is_default).to be(false)
    end

    it "does nothing when the destroyed address wasn't the default" do
      customer = create(:customer)
      default_address = create(:address, customer: customer, is_default: true)
      other = create(:address, customer: customer, is_default: false)

      other.destroy!

      expect(default_address.reload.is_default).to be(true)
    end
  end
end
