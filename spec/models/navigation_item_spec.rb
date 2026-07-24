# frozen_string_literal: true

require "rails_helper"

RSpec.describe NavigationItem do
  describe "#live?" do
    it "is live with no schedule bounds" do
      expect(build(:navigation_item).live?).to be(true)
    end

    it "is not live before starts_at" do
      expect(build(:navigation_item, starts_at: 1.day.from_now).live?).to be(false)
    end

    it "is not live after ends_at" do
      expect(build(:navigation_item, ends_at: 1.day.ago).live?).to be(false)
    end
  end

  describe "scopes" do
    it "live excludes future and expired items" do
      current = create(:navigation_item)
      create(:navigation_item, starts_at: 1.day.from_now)
      create(:navigation_item, ends_at: 1.day.ago)

      expect(NavigationItem.live).to contain_exactly(current)
    end
  end

  it "rejects being its own parent" do
    item = create(:navigation_item)
    item.parent_id = item.id

    expect(item).not_to be_valid
    expect(item.errors[:parent_id]).to be_present
  end
end
