# frozen_string_literal: true

# A snapshot of the address an order ships to — captured fresh at checkout
# (deliberately not a foreign key to the customer's Address book, see
# Address, so editing/deleting a saved address never alters a past order).
# It can be corrected after placement while the order is still eligible
# (Order#update_shipping_address!) — has_paper_trail keeps a full history
# of every such change (old/new values, who, when).
class OrderAddress < ApplicationRecord
  belongs_to :order

  has_paper_trail

  enum :address_type, { shipping: 0 }

  validates :full_name, :phone, :line1, :city, :state, :postal_code, :country, presence: true
end
