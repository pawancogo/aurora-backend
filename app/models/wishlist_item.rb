# frozen_string_literal: true

# A single saved-for-later product on a customer's wishlist.
class WishlistItem < ApplicationRecord
  belongs_to :customer
  belongs_to :product

  validates :product_id, uniqueness: { scope: :customer_id }
end
