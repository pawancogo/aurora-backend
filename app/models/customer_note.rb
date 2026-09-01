# frozen_string_literal: true

# Staff-only note on a customer account (not visible to the shopper).
class CustomerNote < ApplicationRecord
  belongs_to :customer
  belongs_to :admin_user

  validates :body, presence: true, length: { maximum: 2000 }

  scope :recent, -> { order(id: :desc) }
end
