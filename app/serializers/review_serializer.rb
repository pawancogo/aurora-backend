# frozen_string_literal: true

class ReviewSerializer
  def self.collection(reviews, voted_ids: [])
    voted = Array(voted_ids).to_set
    reviews.map { |review| new(review, voted: voted.include?(review.id)).as_json }
  end

  def initialize(review, voted: false)
    @review = review
    @voted = voted
  end

  def as_json(*)
    {
      id: @review.id,
      product_id: @review.product_id,
      product_name: @review.product&.name,
      product_slug: @review.product&.slug,
      rating: @review.rating,
      title: @review.title,
      body: @review.body,
      status: @review.status,
      verified_purchase: @review.verified_purchase,
      helpful_count: @review.helpful_count,
      voted: @voted,
      reviewer_name: @review.reviewer_name,
      images: @review.images.map { |image| { id: image.id, url: image.url, position: image.position } },
      admin_response: @review.admin_response,
      responded_at: @review.responded_at,
      published_at: @review.published_at,
      created_at: @review.created_at
    }
  end
end
