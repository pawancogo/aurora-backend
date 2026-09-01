# frozen_string_literal: true

class ReviewImage < ApplicationRecord
  belongs_to :review, inverse_of: :images

  validates :url, presence: true, length: { maximum: 500 }
  validates :url, format: { with: /\Ahttps?:\/\/.+\z/i, message: "must be an http(s) URL" }
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
