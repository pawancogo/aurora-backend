# frozen_string_literal: true

# A purchasable variation of a product (a specific combination of attribute
# values). Price/MRP fall back to the parent product when nil. Every product
# owns one hidden `master` variant; real variants are created per option combo.
class ProductVariant < ApplicationRecord
  include HasSku

  has_paper_trail

  belongs_to :product
  has_many :variant_option_values, dependent: :destroy, inverse_of: :product_variant
  has_many :attribute_values, through: :variant_option_values
  accepts_nested_attributes_for :variant_option_values, allow_destroy: true
  has_one :inventory_item, dependent: :destroy

  after_create :ensure_inventory_item
  validate :master_has_no_options
  validate :option_combination_is_unique

  scope :master, -> { where(is_master: true) }
  scope :non_master, -> { where(is_master: false) }
  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:position, :id) }

  # Price falls back to the parent product's price when the variant doesn't set one.
  def price_cents_effective
    price_cents || product&.price_cents || 0
  end

  def mrp_cents_effective
    mrp_cents || product&.mrp_cents || 0
  end

  def price
    price_cents_effective / 100.0
  end

  def mrp
    mrp_cents_effective / 100.0
  end

  # Inventory helpers (delegate to the inventory item, tolerant of nil).
  def available
    inventory_item&.available.to_i
  end

  def in_stock?
    inventory_item&.in_stock? || false
  end

  def low_stock?
    inventory_item&.low_stock? || false
  end

  # "Red / M" — the option combination, for admin labels.
  def option_label
    return "Default" if is_master?

    attribute_values.includes(:product_attribute).map(&:value).join(" / ").presence || "Default"
  end

  private

  def ensure_inventory_item
    create_inventory_item! unless inventory_item
  end

  def sku_prefix
    "VAR"
  end

  def master_has_no_options
    return unless is_master? && variant_option_values.reject(&:marked_for_destruction?).any?

    errors.add(:base, "The master variant cannot have options")
  end

  # Two non-master variants of the same product may not share the identical set
  # of attribute values.
  def option_combination_is_unique
    return if is_master?

    my_ids = variant_option_values.reject(&:marked_for_destruction?).map(&:attribute_value_id).compact.sort
    return if my_ids.empty?

    siblings = product&.variants&.non_master&.where.not(id: id) || []
    clash = siblings.any? { |v| v.attribute_values.pluck(:id).sort == my_ids }
    errors.add(:base, "A variant with the same options already exists") if clash
  end
end
