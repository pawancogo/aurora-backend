# frozen_string_literal: true

# A shipping option offered at checkout. No carrier integration — just a
# name, price, and whether it's currently offered.
class ShippingMethod < ApplicationRecord
  has_many :orders, dependent: :nullify

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:position, :id) }

  validates :name, presence: true
  validates :price_cents, numericality: { greater_than_or_equal_to: 0 }

  def price
    price_cents / 100.0
  end
end
