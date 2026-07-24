# frozen_string_literal: true

require "rails_helper"

RSpec.describe AdminUser do
  describe "#can?" do
    it "grants every permission to a super admin" do
      admin = create(:admin_user, :super_admin)

      expect(admin.can?("anything.at.all")).to be(true)
    end

    it "grants only assigned permissions to a regular admin" do
      permission = create(:permission, key: "products.read")
      role = create(:role)
      role.permissions << permission
      admin = create(:admin_user)
      admin.roles << role

      expect(admin.can?("products.read")).to be(true)
      expect(admin.can?("products.manage")).to be(false)
    end
  end

  describe "validations" do
    it "requires a password of at least 10 characters" do
      admin = build(:admin_user, password: "short")

      expect(admin).not_to be_valid
      expect(admin.errors[:password]).to be_present
    end

    it "normalizes the email to lowercase" do
      admin = create(:admin_user, email: "MixedCase@Example.com")

      expect(admin.email).to eq("mixedcase@example.com")
    end
  end
end
