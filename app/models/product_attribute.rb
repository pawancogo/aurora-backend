# frozen_string_literal: true

# A metadata-driven attribute definition (e.g. Color, Size, Storage). Doubles as
# the storefront facet registry via `filterable`/`searchable`. Its values create
# product variants.
class ProductAttribute < ApplicationRecord
  include SearchManager

  search_manager on: %i[name code], aggs_on: %i[filterable searchable]

  has_paper_trail

  has_many :attribute_values, -> { order(:position, :id) },
           dependent: :destroy, inverse_of: :product_attribute
  accepts_nested_attributes_for :attribute_values, allow_destroy: true,
                                reject_if: ->(attrs) { attrs[:value].blank? }

  before_validation :normalize_code

  validates :name, presence: true
  validates :code, presence: true, uniqueness: true,
                   format: { with: /\A[a-z0-9_]+\z/, message: "must be lowercase letters, numbers, or underscores" }

  scope :filterable, -> { where(filterable: true) }
  scope :ordered, -> { order(:position, :id) }

  private

  def normalize_code
    self.code = code.to_s.strip.downcase.gsub(/[^a-z0-9]+/, "_").gsub(/\A_+|_+\z/, "") if code.present?
    self.code = name.to_s.parameterize(separator: "_") if code.blank? && name.present?
  end
end
