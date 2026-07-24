# frozen_string_literal: true

# A directed link from one product to another, powering PDP recommendation rails.
class ProductRelation < ApplicationRecord
  has_paper_trail

  belongs_to :product
  belongs_to :related_product, class_name: "Product"

  enum :relation_kind, {
    related: 0,
    recommended: 1,
    cross_sell: 2,
    up_sell: 3
  }, prefix: :kind

  validates :related_product_id, uniqueness: { scope: %i[product_id relation_kind] }
  validate :not_self_referential

  scope :ordered, -> { order(:position, :id) }

  private

  def not_self_referential
    errors.add(:related_product_id, "can't be the same product") if product_id == related_product_id
  end
end
