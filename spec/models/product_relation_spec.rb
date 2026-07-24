# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProductRelation do
  it "links two products with a kind" do
    a = create(:product)
    b = create(:product)
    relation = ProductRelation.create!(product: a, related_product: b, relation_kind: :recommended)

    expect(a.related_products).to include(b)
    expect(relation).to be_kind_recommended
  end

  it "rejects self-referential relations" do
    a = create(:product)
    relation = ProductRelation.new(product: a, related_product: a)
    expect(relation).not_to be_valid
    expect(relation.errors[:related_product_id]).to include("can't be the same product")
  end

  it "rejects duplicates of the same kind" do
    a = create(:product)
    b = create(:product)
    ProductRelation.create!(product: a, related_product: b, relation_kind: :related)
    dup = ProductRelation.new(product: a, related_product: b, relation_kind: :related)

    expect(dup).not_to be_valid
  end

  it "allows the same pair under a different kind" do
    a = create(:product)
    b = create(:product)
    ProductRelation.create!(product: a, related_product: b, relation_kind: :related)
    other = ProductRelation.new(product: a, related_product: b, relation_kind: :cross_sell)

    expect(other).to be_valid
  end
end
