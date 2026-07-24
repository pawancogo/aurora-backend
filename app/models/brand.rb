# frozen_string_literal: true

class Brand < ApplicationRecord
  include Sluggable
  include Discardable
  include SearchManager

  search_manager on: %i[name slug]
  has_paper_trail

  has_many :products, dependent: :nullify

  validates :name, presence: true
end
