# frozen_string_literal: true

class TaxClass < ApplicationRecord
  has_many :products, dependent: :nullify
  has_paper_trail

  validates :name, presence: true, uniqueness: true
  validates :rate, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
end
