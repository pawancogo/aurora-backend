# frozen_string_literal: true

require "rails_helper"

RSpec.describe Shipment do
  it "allows only one shipment per order" do
    order = create(:order)
    create(:shipment, order: order)

    duplicate = build(:shipment, order: order)
    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:order_id]).to be_present
  end

  it "treats blank carrier and tracking as nil" do
    shipment = create(:shipment, carrier_name: "  ", tracking_number: "")

    expect(shipment.carrier_name).to be_nil
    expect(shipment.tracking_number).to be_nil
  end

  describe "#apply_details!" do
    it "records a tracking note the first time a tracking number is set" do
      shipment = create(:shipment, carrier_name: nil, tracking_number: nil)

      shipment.apply_details!(carrier_name: "BlueDart", tracking_number: "AWB123", packing_notes: "Handle with care")

      expect(shipment.reload.packing_notes).to eq("Handle with care")
      expect(shipment.events.note.map(&:description)).to eq([ "Tracking · BlueDart · AWB123" ])
    end

    it "does not add another tracking note on a later edit" do
      shipment = create(:shipment, carrier_name: "BlueDart", tracking_number: "AWB123")

      shipment.apply_details!(carrier_name: "Delhivery", tracking_number: "AWB123")

      expect(shipment.events.note).to be_empty
      expect(shipment.reload.carrier_name).to eq("Delhivery")
    end
  end
end
