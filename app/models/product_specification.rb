# frozen_string_literal: true

# A descriptive spec row for the PDP (e.g. "Material: Cotton"), optionally grouped.
class ProductSpecification < ApplicationRecord
  has_paper_trail

  belongs_to :product

  validates :name, presence: true
  validates :value, presence: true

  scope :ordered, -> { order(:position, :id) }
end
