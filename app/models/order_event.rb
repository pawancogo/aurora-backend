# frozen_string_literal: true

# A manually-logged delivery update ("Package handed to courier", "Out for
# delivery") shown to the shopper on their order page. No carrier
# integration writes these today — staff add them by hand from the admin.
class OrderEvent < ApplicationRecord
  belongs_to :order

  validates :description, :occurred_at, presence: true
end
