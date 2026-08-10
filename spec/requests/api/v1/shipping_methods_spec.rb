# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::ShippingMethods" do
  def data
    response.parsed_body["data"]
  end

  it "lists only active shipping methods, ordered by position" do
    create(:shipping_method, name: "Inactive", active: false)
    second = create(:shipping_method, name: "Express", position: 2)
    first = create(:shipping_method, name: "Standard", position: 1)

    get "/api/v1/shipping_methods"

    expect(data.map { |m| m["name"] }).to eq([ first.name, second.name ])
  end
end
