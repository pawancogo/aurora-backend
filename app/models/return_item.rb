# frozen_string_literal: true

# A line on a return request — which order item and how many units come back.
class ReturnItem < ApplicationRecord
  belongs_to :return_request
  belongs_to :order_item

  validates :quantity, numericality: { only_integer: true, greater_than: 0 }
  validate :quantity_within_ordered

  private

  def quantity_within_ordered
    return if order_item.blank? || quantity.blank?
    return if quantity <= order_item.quantity

    errors.add(:quantity, "can't exceed the quantity ordered")
  end
end
