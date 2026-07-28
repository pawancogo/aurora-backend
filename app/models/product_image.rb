# frozen_string_literal: true

class ProductImage < ApplicationRecord
  belongs_to :product
  # Optional binding to a variant option value (e.g. a colour); NULL = shared.
  belongs_to :attribute_value, optional: true
  has_paper_trail

  validates :source_url, presence: true

  scope :ordered, -> { order(:position, :id) }
  scope :shared, -> { where(attribute_value_id: nil) }
end
