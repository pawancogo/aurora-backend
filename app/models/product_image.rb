# frozen_string_literal: true

class ProductImage < ApplicationRecord
  belongs_to :product
  has_paper_trail

  validates :source_url, presence: true

  scope :ordered, -> { order(:position, :id) }
end
