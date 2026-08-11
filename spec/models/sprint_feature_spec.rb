# frozen_string_literal: true

require "rails_helper"

RSpec.describe SprintFeature do
  it "requires a title" do
    expect(build(:sprint_feature, title: nil)).not_to be_valid
  end

  it "strips disallowed tags/attributes from the description on save" do
    feature = create(:sprint_feature,
      description: "<script>alert(1)</script><p onclick=\"evil()\">Hello <b>world</b></p>")

    expect(feature.description).to eq("alert(1)<p>Hello <b>world</b></p>")
    expect(feature.description).not_to include("<script")
    expect(feature.description).not_to include("onclick")
  end

  it "strips disallowed tags/attributes from the technical description on save" do
    feature = create(:sprint_feature, technical_description: "<script>alert(1)</script><p>Safe</p>")

    expect(feature.technical_description).to eq("alert(1)<p>Safe</p>")
    expect(feature.technical_description).not_to include("<script")
  end

  it "orders by position" do
    sprint = create(:sprint)
    second = create(:sprint_feature, sprint: sprint, position: 2)
    first = create(:sprint_feature, sprint: sprint, position: 1)

    expect(sprint.sprint_features.ordered).to eq([ first, second ])
  end
end
