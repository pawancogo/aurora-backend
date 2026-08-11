# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sprint do
  it "requires a unique number and a title" do
    existing = create(:sprint)

    expect(build(:sprint, number: existing.number)).not_to be_valid
    expect(build(:sprint, title: nil)).not_to be_valid
  end

  it "orders by number" do
    create(:sprint, number: 9, title: "Nine")
    create(:sprint, number: 8, title: "Eight")

    expect(Sprint.ordered.pluck(:number)).to eq([ 8, 9 ])
  end

  it "destroys its features when destroyed" do
    sprint = create(:sprint)
    create(:sprint_feature, sprint: sprint)

    expect { sprint.destroy }.to change(SprintFeature, :count).by(-1)
  end
end
