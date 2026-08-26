# frozen_string_literal: true

module Api
  module V1
    # Public review list on a PDP plus authenticated create (verified purchase).
    class ProductReviewsController < BaseController
      include CustomerAuthentication
      include ReviewsFeature

      before_action :require_reviews_enabled!
      before_action :authenticate_customer!, only: :create

      rescue_from Review::Error do |error|
        render_error(code: "review_not_allowed", message: error.message)
      end

      # GET /api/v1/products/:product_id/reviews
      def index
        product = find_live_product!
        scope = product.reviews.published.includes(:customer, :images, :votes)
        scope = scope.where(rating: params[:rating]) if params[:rating].present?
        scope = scope.joins(:images).distinct if truthy?(params[:with_photos])
        scope = scope.sorted(params[:sort])
        reviews, meta = paginate(scope)
        render_success(
          ReviewSerializer.collection(reviews, voted_ids: voted_ids_for(reviews)),
          meta: meta.merge(eligibility_meta(product), ratings_meta(product))
        )
      end

      # POST /api/v1/products/:product_id/reviews
      def create
        product = find_live_product!
        review = Review.submit!(
          product: product,
          customer: current_customer,
          rating: params[:rating],
          title: params[:title],
          body: params[:body],
          image_urls: params[:image_urls]
        )
        render_success(ReviewSerializer.new(review).as_json, status: :created)
      end

      private

      def voted_ids_for(reviews)
        return [] unless current_customer

        ReviewVote.where(customer: current_customer, review_id: reviews.map(&:id)).pluck(:review_id)
      end

      def eligibility_meta(product)
        return { can_review: false, already_reviewed: false } unless current_customer

        {
          can_review: Review.eligible?(customer: current_customer, product: product),
          already_reviewed: product.reviews.exists?(customer: current_customer)
        }
      end

      def ratings_meta(product)
        {
          rating_avg: product.rating_avg.to_f,
          rating_count: product.rating_count,
          rating_distribution: Review.distribution_for(product)
        }
      end

      def truthy?(value)
        ActiveModel::Type::Boolean.new.cast(value)
      end
    end
  end
end
