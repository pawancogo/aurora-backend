# frozen_string_literal: true

# Join: a variant attribute that applies to a category (inherited by descendants).
class CategoryAttribute < ApplicationRecord
  belongs_to :category
  belongs_to :product_attribute

  validates :product_attribute_id, uniqueness: { scope: :category_id }
end
