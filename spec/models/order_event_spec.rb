# frozen_string_literal: true

require "rails_helper"

RSpec.describe OrderEvent do
  it "requires a description and an occurred_at" do
    event = build(:order_event, description: nil, occurred_at: nil)
    expect(event).not_to be_valid
    expect(event.errors.attribute_names).to include(:description, :occurred_at)
  end

  it "orders an order's events chronologically regardless of creation order" do
    order = create(:order)
    later = create(:order_event, order: order, occurred_at: 1.hour.ago)
    earlier = create(:order_event, order: order, occurred_at: 2.hours.ago)

    expect(order.order_events.to_a).to eq([ earlier, later ])
  end
end
