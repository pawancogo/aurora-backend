# frozen_string_literal: true

# Immutable address snapshot captured at checkout — deliberately not a
# foreign key to the customer's Address book (see Address), so a shopper
# editing/deleting a saved address never alters a past order. Editing/
# versioning this after placement is a later sprint's concern (Delivery &
# Address Change Workflow), not this one.
class OrderAddress < ApplicationRecord
  belongs_to :order

  enum :address_type, { shipping: 0 }

  validates :full_name, :phone, :line1, :city, :state, :postal_code, :country, presence: true
end
