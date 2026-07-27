# frozen_string_literal: true

require "rails_helper"

RSpec.describe Cms::Homepage do
  subject(:payload) { described_class.new.as_json }

  it "returns live sections in order, excluding hidden and scheduled-future ones" do
    create(:homepage_section, :hero, position: 1, title: "Hero")
    create(:homepage_section, position: 2, title: "New")
    create(:homepage_section, :hidden, position: 3, title: "Hidden")
    create(:homepage_section, :scheduled_future, position: 4, title: "Later")

    expect(payload[:sections].map { |s| s[:title] }).to eq(%w[Hero New])
  end

  it "resolves a product_rail to live products for its source" do
    create(:product, new_arrival: true, name: "Fresh Tee")
    create(:product, new_arrival: false, name: "Old Tee")
    create(:homepage_section, section_type: "product_rail", config: { "source" => "new_arrival", "limit" => 4 })

    rail = payload[:sections].find { |s| s[:type] == "product_rail" }
    names = rail[:data][:products].map { |p| p[:name] }
    expect(names).to include("Fresh Tee")
    expect(names).not_to include("Old Tee")
  end

  it "resolves hero sections to live banners of the matching placement" do
    create(:banner, placement: "hero", title: "Shown")
    create(:banner, :scheduled_future, placement: "hero", title: "Future")
    create(:homepage_section, :hero)

    hero = payload[:sections].find { |s| s[:type] == "hero" }
    expect(hero[:data][:banners].map { |b| b[:title] }).to eq(%w[Shown])
  end

  it "exposes the active announcement and the footer" do
    create(:banner, :announcement, title: "Sale on now")
    create(:footer_section, heading: "Company", links: [ { "label" => "About", "url" => "/p/about" }, { "label" => "", "url" => "" } ])

    expect(payload[:announcement]).to include(title: "Sale on now")
    expect(payload[:footer]).to eq([ { heading: "Company", links: [ { "label" => "About", "url" => "/p/about" } ] } ])
  end
end
