# frozen_string_literal: true

module Admin
  class ReviewsController < BaseController
    before_action -> { require_permission!("reviews.read") }, only: %i[index show]
    before_action -> { require_permission!("reviews.manage") }, only: %i[publish hide respond]
    before_action :set_review, only: %i[show publish hide respond]

    def index
      scope = Review.includes(:customer, :product).recent
      result = Review.search(params, scope: scope)
      @facets = result.facets
      @reviews = result.records
    end

    def show
    end

    def publish
      @review.publish!
      redirect_to admin_review_path(@review), notice: "Review published."
    rescue Review::Error => e
      redirect_to admin_review_path(@review), alert: e.message
    end

    def hide
      @review.hide!
      redirect_to admin_review_path(@review), notice: "Review hidden."
    rescue Review::Error => e
      redirect_to admin_review_path(@review), alert: e.message
    end

    def respond
      @review.respond!(params[:admin_response])
      redirect_to admin_review_path(@review), notice: "Store response saved."
    rescue Review::Error => e
      redirect_to admin_review_path(@review), alert: e.message
    end

    private

    def set_review
      @review = Review.includes(:customer, :product, :images).find(params[:id])
    end
  end
end
