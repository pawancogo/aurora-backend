# frozen_string_literal: true

# Immutable address snapshot captured at checkout — not a foreign key to a
# customer's address book (that book doesn't exist yet; canonical "Customer
# Profile & Address Book" sprint is still pending). Editing/versioning this
# after placement is a later sprint's concern (Delivery & Address Change
# Workflow), not this one.
class OrderAddress < ApplicationRecord
  belongs_to :order

  enum :address_type, { shipping: 0 }

  validates :full_name, :phone, :line1, :city, :state, :postal_code, :country, presence: true
end
