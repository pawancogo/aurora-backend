# frozen_string_literal: true

require "rails_helper"

RSpec.describe Navigation::TreeBuilder do
  let!(:root)   { create(:navigation_item, label: "Root", position: 1) }
  let!(:child)  { create(:navigation_item, label: "Child", parent: root, position: 1) }
  let!(:hidden) { create(:navigation_item, :hidden, label: "Hidden", position: 2) }
  let!(:future) { create(:navigation_item, label: "Future", starts_at: 1.day.from_now, position: 3) }

  it "nests children under their parent" do
    tree = described_class.new(scope: :public).as_json
    root_node = tree.find { |node| node[:label] == "Root" }

    expect(root_node[:children].map { |c| c[:label] }).to eq([ "Child" ])
  end

  it "excludes hidden and not-yet-live items for the public scope" do
    labels = described_class.new(scope: :public).as_json.map { |n| n[:label] }

    expect(labels).to include("Root")
    expect(labels).not_to include("Hidden", "Future")
  end

  it "includes hidden and scheduled items for the admin scope" do
    labels = described_class.new(scope: :admin).as_json.map { |n| n[:label] }

    expect(labels).to include("Root", "Hidden", "Future")
  end
end
