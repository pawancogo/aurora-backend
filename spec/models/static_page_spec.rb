# frozen_string_literal: true

require "rails_helper"

RSpec.describe StaticPage do
  it "auto-generates a slug from the title" do
    page = create(:static_page, title: "Shipping & Returns")
    expect(page.slug).to eq("shipping-returns")
  end

  it "keeps a supplied slug and enforces uniqueness" do
    create(:static_page, slug: "about")
    expect(build(:static_page, slug: "about")).not_to be_valid
  end

  it ".published excludes drafts" do
    live = create(:static_page, published: true)
    create(:static_page, published: false)
    expect(StaticPage.published).to contain_exactly(live)
  end
end
