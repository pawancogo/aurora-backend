# frozen_string_literal: true

class Product < ApplicationRecord
  include Sluggable
  include Discardable
  include SearchManager

  search_manager on: %i[name sku search_keywords],
                 aggs_on: %i[status brand_id category_id featured new_arrival best_seller],
                 range_on: :price_cents

  has_paper_trail

  enum :status, { draft: 0, active: 1, archived: 2 }

  belongs_to :brand, optional: true
  belongs_to :category, optional: true
  belongs_to :tax_class, optional: true
  has_many :product_images, -> { order(:position, :id) },
           dependent: :destroy, inverse_of: :product
  accepts_nested_attributes_for :product_images, allow_destroy: true

  # Auto-generate a unique SKU when none is supplied (a manual one is still allowed).
  before_validation :generate_sku, if: -> { sku.blank? }

  validates :name, presence: true
  validates :sku, presence: true, uniqueness: true
  validates :price_cents, :mrp_cents, numericality: { greater_than_or_equal_to: 0 }

  # Publicly visible = active and past its (optional) publish time.
  scope :live, -> { active.where("published_at IS NULL OR published_at <= ?", Time.current) }
  scope :featured, -> { where(featured: true) }
  scope :new_arrivals, -> { where(new_arrival: true) }
  scope :best_sellers, -> { where(best_seller: true) }

  def price
    price_cents / 100.0
  end

  def mrp
    mrp_cents / 100.0
  end

  def discount_percent
    return 0 if mrp_cents.zero? || mrp_cents <= price_cents

    (((mrp_cents - price_cents).to_f / mrp_cents) * 100).round
  end

  def primary_image
    product_images.detect(&:primary) || product_images.first
  end

  private

  # "SKU-XXXXXXXX" with a random suffix; the DB unique index is the final guard.
  def generate_sku
    loop do
      candidate = "SKU-#{SecureRandom.alphanumeric(8).upcase}"
      break self.sku = candidate unless self.class.where.not(id: id).exists?(sku: candidate)
    end
  end
end
