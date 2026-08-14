# frozen_string_literal: true

require "rails_helper"

RSpec.describe OrderAddress do
  it "requires the core address fields" do
    address = build(:order_address, full_name: nil, line1: nil)
    expect(address).not_to be_valid
    expect(address.errors.attribute_names).to include(:full_name, :line1)
  end

  it "keeps a version for every change, so past edits can be audited" do
    address = create(:order_address, full_name: "Original Name")
    expect(address.versions.count).to eq(1)

    address.update!(full_name: "Corrected Name")

    expect(address.versions.count).to eq(2)
    expect(address.versions.last.reify.full_name).to eq("Original Name")
  end
end
