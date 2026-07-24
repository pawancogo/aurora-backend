# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Navigation", type: :request do
  it "returns the nested, visible navigation tree" do
    men = create(:navigation_item, label: "Men", position: 1)
    create(:navigation_item, label: "Shirts", parent: men, position: 1)
    create(:navigation_item, :hidden, label: "Hidden Root", position: 2)

    get "/api/v1/navigation"

    expect(response).to have_http_status(:ok)
    data = response.parsed_body["data"]
    labels = data.map { |n| n["label"] }
    expect(labels).to include("Men")
    expect(labels).not_to include("Hidden Root")

    men_node = data.find { |n| n["label"] == "Men" }
    expect(men_node["children"].map { |c| c["label"] }).to eq([ "Shirts" ])
  end
end
