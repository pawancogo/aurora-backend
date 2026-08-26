# frozen_string_literal: true

require "rails_helper"

RSpec.describe Address do
  it "makes the first address the default" do
    address = create(:address)

    expect(address.is_default).to be(true)
  end

  it "keeps a later address non-default unless asked" do
    customer = create(:customer)
    create(:address, customer: customer)
    second = create(:address, customer: customer, address_type: :office, line1: "456 Work Ave")

    expect(second.is_default).to be(false)
    expect(customer.addresses.where(is_default: true).count).to eq(1)
  end

  it "switches the default to a single address" do
    customer = create(:customer)
    first = create(:address, customer: customer)
    second = create(:address, customer: customer, address_type: :office, line1: "456 Work Ave")

    second.make_default!

    expect(second.reload.is_default).to be(true)
    expect(first.reload.is_default).to be(false)
  end

  it "unsets the previous default when a new default is created" do
    customer = create(:customer)
    first = create(:address, customer: customer)
    second = create(:address, customer: customer, address_type: :office, line1: "456 Work Ave", is_default: true)

    expect(second.is_default).to be(true)
    expect(first.reload.is_default).to be(false)
  end

  it "promotes another address when the default is deleted" do
    customer = create(:customer)
    first = create(:address, customer: customer)
    second = create(:address, customer: customer, address_type: :office, line1: "456 Work Ave")

    first.destroy!

    expect(second.reload.is_default).to be(true)
  end

  it "rejects a new address once the per-customer limit is reached" do
    create(:site_setting, key: "addresses.max_per_customer", value: 2, value_type: "number")
    customer = create(:customer)
    create(:address, customer: customer)
    create(:address, customer: customer, address_type: :office, line1: "456 Work Ave")

    extra = build(:address, customer: customer, address_type: :other, line1: "789 Other Rd")

    expect(extra).not_to be_valid
    expect(extra.errors[:base].join).to include("maximum of 2")
  end
end
