# frozen_string_literal: true

module Api
  module V1
    class ReviewVotesController < BaseController
      include CustomerAuthentication
      include ReviewsFeature

      before_action :require_reviews_enabled!
      before_action :authenticate_customer!

      # POST /api/v1/reviews/:id/vote — toggle a helpful vote.
      def create
        review = Review.published.find(params[:id])
        review.toggle_vote!(current_customer)
        voted = review.votes.exists?(customer: current_customer)
        render_success(ReviewSerializer.new(review, voted: voted).as_json)
      end
    end
  end
end
