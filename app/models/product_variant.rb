# frozen_string_literal: true

# A purchasable variation of a product (a specific combination of attribute
# values) — the ONLY place a price is ever set. Every product owns one hidden
# `master` variant (the sellable unit for products with no real options);
# real variants are created per option combo. Product#price_cents/#mrp_cents
# are a read-only cache of the cheapest sellable variant's price, kept in
# sync by `sync_product_pricing` below — a product never has its own price.
class ProductVariant < ApplicationRecord
  include HasSku

  has_paper_trail

  belongs_to :product
  has_many :variant_option_values, dependent: :destroy, inverse_of: :product_variant
  has_many :attribute_values, through: :variant_option_values
  accepts_nested_attributes_for :variant_option_values, allow_destroy: true
  has_one :inventory_item, dependent: :destroy

  after_create :ensure_inventory_item
  after_commit :sync_product_pricing
  validate :master_has_no_options
  validate :option_combination_is_unique
  validates :price_cents, :mrp_cents, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  scope :master, -> { where(is_master: true) }
  scope :non_master, -> { where(is_master: false) }
  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:position, :id) }

  # The variants a product actually sells: every non-master variant, plus the
  # master only when the product has no real variants. Used by the inventory list.
  scope :purchasable, lambda {
    where("product_variants.is_master = FALSE OR NOT EXISTS (" \
          "SELECT 1 FROM product_variants m WHERE m.product_id = product_variants.product_id " \
          "AND m.is_master = FALSE)")
  }

  def price
    price_cents.to_i / 100.0
  end

  def mrp
    mrp_cents.to_i / 100.0
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

  # Keeps Product's cached price_cents/mrp_cents matching whichever sellable
  # variant is currently cheapest — fires on create/update/destroy so any
  # change here (price, active flag, or removal) propagates automatically.
  # Search/sort (SearchManager's range_on, Products::Search) need a real
  # queryable column on products, so this can't just be computed on read.
  def sync_product_pricing
    product&.sync_pricing!
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
