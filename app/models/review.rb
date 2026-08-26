# frozen_string_literal: true

# A customer's star rating + written review of a product they purchased.
# New reviews start pending; staff publish or hide them. Only published
# reviews count toward the product's cached rating_avg / rating_count.
class Review < ApplicationRecord
  include SearchManager

  search_manager on: %i[title body], aggs_on: %i[status rating verified_purchase]

  class Error < StandardError; end

  PURCHASED_STATUSES = %w[delivered returned].freeze
  MAX_IMAGES = 5
  MIN_BODY = 20
  SORTS = {
    "newest" => { published_at: :desc, id: :desc },
    "helpful" => { helpful_count: :desc, published_at: :desc, id: :desc },
    "rating_desc" => { rating: :desc, published_at: :desc, id: :desc },
    "rating_asc" => { rating: :asc, published_at: :desc, id: :desc }
  }.freeze

  belongs_to :product
  belongs_to :customer
  has_many :images, -> { order(:position, :id) }, class_name: "ReviewImage", dependent: :destroy, inverse_of: :review
  has_many :votes, class_name: "ReviewVote", dependent: :destroy, inverse_of: :review

  has_paper_trail

  enum :status, { pending: 0, published: 1, hidden: 2 }, validate: true

  validates :rating, numericality: { only_integer: true, in: 1..5 }
  validates :title, length: { maximum: 120 }, allow_blank: true
  validates :body, presence: true, length: { minimum: MIN_BODY, maximum: 4000 }
  validates :admin_response, length: { maximum: 2000 }, allow_blank: true
  validates :customer_id, uniqueness: { scope: :product_id, message: "already reviewed this product" }

  after_commit :recalculate_product_ratings

  scope :recent, -> { order(id: :desc) }
  scope :visible, -> { published }

  def self.purchased?(customer:, product:)
    Order.where(customer: customer, status: PURCHASED_STATUSES)
         .joins(order_items: :product_variant)
         .where(product_variants: { product_id: product.id })
         .exists?
  end

  def self.eligible?(customer:, product:)
    purchased?(customer: customer, product: product) && !exists?(customer: customer, product: product)
  end

  def self.submit!(product:, customer:, rating:, title: nil, body:, image_urls: nil)
    raise Error, "You can only review a product after a delivered order." unless purchased?(customer: customer, product: product)
    raise Error, "You've already reviewed this product." if exists?(customer: customer, product: product)

    transaction do
      review = create!(
        product: product,
        customer: customer,
        rating: rating,
        title: title.to_s.strip.presence,
        body: body.to_s.strip,
        verified_purchase: true,
        status: :pending
      )
      review.attach_images!(image_urls)
      review
    end
  end

  def self.sorted(sort)
    order(SORTS[sort.to_s] || SORTS["newest"])
  end

  def self.distribution_for(product)
    stored = product.rating_distribution || {}
    (1..5).each_with_object({}) do |stars, hash|
      hash[stars.to_s] = stored[stars.to_s].to_i.nonzero? || stored[stars].to_i
    end
  end

  def attach_images!(urls)
    Array(urls).first(MAX_IMAGES).each_with_index do |url, index|
      images.create!(url: url.to_s.strip, position: index)
    end
  end

  def publish!
    raise Error, "This review is already published." if published?

    update!(status: :published, published_at: published_at || Time.current)
  end

  def hide!
    raise Error, "This review is already hidden." if hidden?

    update!(status: :hidden)
  end

  def respond!(body)
    text = body.to_s.strip
    raise Error, "Response can't be blank." if text.blank?

    update!(admin_response: text, responded_at: Time.current)
  end

  def toggle_vote!(customer)
    existing = votes.find_by(customer: customer)
    if existing
      existing.destroy!
    else
      votes.create!(customer: customer)
    end
    update_column(:helpful_count, votes.count)
    reload
  end

  def reviewer_name
    first = customer.first_name.to_s.strip
    last = customer.last_name.to_s.strip
    return "Verified buyer" if first.blank?

    last.present? ? "#{first} #{last[0]}." : first
  end

  private

  def recalculate_product_ratings
    Reviews::RecalculateRatings.new(product).call
  end
end
