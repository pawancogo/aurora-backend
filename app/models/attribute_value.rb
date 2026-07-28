# frozen_string_literal: true

# An allowed value of a ProductAttribute (e.g. Color → "Red"). `metadata` carries
# presentation hints (e.g. { "hex" => "#ff0000" } for a colour swatch).
class AttributeValue < ApplicationRecord
  has_paper_trail

  belongs_to :product_attribute
  has_many :variant_option_values, dependent: :destroy
  has_many :product_variants, through: :variant_option_values
  # Images bound to this option value survive its removal as shared images.
  has_many :product_images, dependent: :nullify

  before_validation :normalize_code

  validates :value, presence: true
  validates :code, presence: true, uniqueness: { scope: :product_attribute_id }

  scope :ordered, -> { order(:position, :id) }

  def label
    "#{product_attribute&.name}: #{value}"
  end

  private

  def normalize_code
    self.code = code.to_s.strip.downcase.gsub(/[^a-z0-9]+/, "_").gsub(/\A_+|_+\z/, "") if code.present?
    self.code = value.to_s.parameterize(separator: "_") if code.blank? && value.present?
  end
end
