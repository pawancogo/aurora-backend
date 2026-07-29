# frozen_string_literal: true

# A shopping cart. Owned by a customer once signed in, otherwise a guest cart
# identified by `token`. Line prices are computed live from the variant, so the
# cart always reflects current pricing/stock (see Carts::Manager).
class Cart < ApplicationRecord
  belongs_to :customer, optional: true
  has_many :cart_items, dependent: :destroy
  has_many :product_variants, through: :cart_items

  before_validation :ensure_token, on: :create
  validates :token, presence: true, uniqueness: true

  def items
    cart_items.includes(product_variant: [ :product, { variant_option_values: { attribute_value: :product_attribute } } ]).order(:id)
  end

  def item_count
    cart_items.sum(:quantity)
  end

  def subtotal_cents
    cart_items.to_a.sum(&:line_total_cents)
  end

  private

  def ensure_token
    self.token ||= SecureRandom.uuid
  end
end
