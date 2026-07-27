# frozen_string_literal: true

require "rails_helper"

RSpec.describe Banner do
  describe "scheduling (Schedulable)" do
    it "includes a visible, in-window banner in .live" do
      banner = create(:banner)
      expect(Banner.live).to include(banner)
    end

    it "excludes hidden, not-yet-started, and expired banners" do
      create(:banner, :hidden)
      create(:banner, :scheduled_future)
      create(:banner, :expired)
      expect(Banner.live).to be_empty
    end

    it "#live? reflects visibility + window" do
      expect(create(:banner)).to be_live
      expect(create(:banner, :scheduled_future)).not_to be_live
      expect(create(:banner, :expired)).not_to be_live
    end
  end

  describe "placement" do
    it "supports hero/promo/announcement and scopes by it" do
      hero = create(:banner)
      announcement = create(:banner, :announcement)
      expect(Banner.announcement).to contain_exactly(announcement)
      expect(hero).to be_hero
    end

    it "requires a title for announcements" do
      expect(build(:banner, placement: "announcement", title: nil)).not_to be_valid
    end
  end
end
