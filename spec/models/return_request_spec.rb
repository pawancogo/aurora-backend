# frozen_string_literal: true

require "rails_helper"

RSpec.describe ReturnRequest do
  def delivered_order
    order = create(:order, status: :delivered)
    create(:order_item, order: order)
    order
  end

  describe ".request!" do
    it "opens an RMA for a delivered order and copies every line" do
      order = delivered_order

      request = described_class.request!(order: order, reason: "Damaged or defective")

      expect(request).to be_requested
      expect(request).to be_refund
      expect(request.rma_number).to match(/\ARMA-[A-Z0-9]{10}\z/)
      expect(request.return_items.map(&:quantity)).to eq([ 2 ])
    end

    it "rejects an order that isn't delivered" do
      order = create(:order, status: :shipped)
      create(:order_item, order: order)

      expect {
        described_class.request!(order: order, reason: "Changed my mind")
      }.to raise_error(ReturnRequest::Error, /can't be returned/i)
    end

    it "rejects a second open request on the same order" do
      order = delivered_order
      described_class.request!(order: order, reason: "Size doesn't fit")

      expect {
        described_class.request!(order: order, reason: "Changed my mind")
      }.to raise_error(ReturnRequest::Error, /can't be returned/i)
    end
  end

  describe "staff lifecycle" do
    it "approves, receives (restocks), and completes a refund RMA" do
      order = delivered_order
      payment = create(:payment, order: order, status: :captured)
      variant = order.order_items.first.product_variant
      variant.inventory_item.update!(on_hand: 3)
      request = described_class.request!(order: order, reason: "Size doesn't fit")

      request.approve!
      expect(request.reload).to be_approved

      request.receive!
      expect(request.reload).to be_received
      expect(variant.inventory_item.reload.on_hand).to eq(5)
      expect(request.return_items.first).to be_restocked

      request.complete!
      expect(request.reload).to be_completed
      expect(order.reload).to be_returned
      expect(payment.reload).to be_refund_pending
    end

    it "completes an exchange without flagging a refund" do
      order = delivered_order
      payment = create(:payment, order: order, status: :captured)
      request = described_class.request!(order: order, reason: "Size doesn't fit", resolution: :exchange)

      request.approve!
      request.receive!
      request.complete!

      expect(order.reload).to be_delivered
      expect(payment.reload).to be_captured
      expect(request.reload).to be_completed
    end

    it "requires a note to reject" do
      request = create(:return_request)

      expect { request.reject!(note: "") }.to raise_error(ReturnRequest::Error, /note/i)
      expect(request.reload).to be_requested
    end
  end
end
