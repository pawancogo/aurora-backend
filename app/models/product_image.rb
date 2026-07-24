# frozen_string_literal: true

class ProductImage < ApplicationRecord
  belongs_to :product

  validates :source_url, presence: true

  scope :ordered, -> { order(:position, :id) }
end
