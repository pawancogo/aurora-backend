# frozen_string_literal: true

class ReviewVote < ApplicationRecord
  belongs_to :review, inverse_of: :votes
  belongs_to :customer

  validates :customer_id, uniqueness: { scope: :review_id }
end
