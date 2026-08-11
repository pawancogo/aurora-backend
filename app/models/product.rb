# frozen_string_literal: true

class Product < ApplicationRecord
  include Sluggable
  include Discardable
  include SearchManager
  include HasSku

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

  has_many :variants, -> { order(:position, :id) },
           class_name: "ProductVariant", dependent: :destroy, inverse_of: :product
  has_many :specifications, -> { order(:position, :id) },
           class_name: "ProductSpecification", dependent: :destroy, inverse_of: :product
  accepts_nested_attributes_for :specifications, allow_destroy: true,
                                reject_if: ->(attrs) { attrs[:name].blank? && attrs[:value].blank? }
  has_many :product_relations, -> { order(:position, :id) }, dependent: :destroy, inverse_of: :product
  has_many :related_products, through: :product_relations

  # Every product owns one hidden master variant that carries default price +
  # inventory until real option variants exist.
  after_create :ensure_master_variant

  validates :name, presence: true

  # Publicly visible = active and past its (optional) publish time.
  scope :live, -> { active.where("published_at IS NULL OR published_at <= ?", Time.current) }
  scope :featured, -> { where(featured: true) }
  scope :new_arrivals, -> { where(new_arrival: true) }
  scope :best_sellers, -> { where(best_seller: true) }

  # price_cents/mrp_cents are the cheapest sellable variant's price, cached on
  # this record by #sync_pricing! so search/sort/filter (SearchManager's
  # range_on, Products::Search) can query them directly. Nothing else should
  # ever assign these columns — set price on a variant instead.
  def price
    price_cents.to_i / 100.0
  end

  def mrp
    mrp_cents.to_i / 100.0
  end

  def discount_percent
    return 0 if mrp_cents.to_i.zero? || mrp_cents.to_i <= price_cents.to_i

    (((mrp_cents - price_cents).to_f / mrp_cents) * 100).round
  end

  # A bare product is never itself the sellable unit — every price is set on
  # a variant. Recomputes and writes this product's cached price_cents/
  # mrp_cents from whichever sellable variant is currently cheapest; called
  # by ProductVariant whenever a variant is created, changed, or removed.
  def sync_pricing!
    cheapest = sellable_variants.min_by(&:price_cents)
    update_columns(price_cents: cheapest&.price_cents || 0, mrp_cents: cheapest&.mrp_cents || 0)
  end

  def primary_image
    product_images.detect(&:primary) || product_images.first
  end

  # The option-less master variant (created automatically).
  def master_variant
    variants.detect(&:is_master?) || variants.find_by(is_master: true)
  end

  # Real, non-master variants define this product's options.
  def has_variants?
    variants.non_master.exists?
  end

  # The variant attributes offered when building this product's variants:
  # those linked to its category (or any ancestor category). Falls back to all
  # attributes that have values when the category has no links configured, so
  # nothing breaks for uncategorised products or before links are set up.
  def applicable_attributes
    base = category_linked_attributes
    base = ProductAttribute.all unless base.exists?
    base.ordered.includes(:attribute_values).select { |attribute| attribute.attribute_values.any? }
  end

  # The distinct attributes this product varies on (drives the PDP selector),
  # ordered by the attribute registry position.
  def option_attributes
    ProductAttribute
      .where(id: AttributeValue.where(id: variant_option_value_ids).select(:product_attribute_id))
      .ordered
  end

  # Total sellable stock across sellable variants.
  def total_available
    sellable_variants.sum { |variant| variant.available }
  end

  def in_stock?
    sellable_variants.any?(&:in_stock?)
  end

  # Variants a customer can actually buy: real active variants, or the master
  # when the product has no options.
  def sellable_variants
    has_variants? ? variants.non_master.active : variants.master
  end

  private

  # Attributes linked to this product's category or any of its ancestors.
  def category_linked_attributes
    return ProductAttribute.none unless category

    category_ids = [ category.id ] + category.ancestors.map(&:id)
    ProductAttribute.joins(:category_attributes)
                    .where(category_attributes: { category_id: category_ids }).distinct
  end

  def variant_option_value_ids
    VariantOptionValue.where(product_variant_id: variants.select(:id)).select(:attribute_value_id)
  end

  def ensure_master_variant
    variants.create!(is_master: true) unless master_variant
  end
end
