# frozen_string_literal: true

module Api
  module V1
    # Signed-in shopper: reviews already written, plus products still waiting.
    class AccountReviewsController < BaseController
      include CustomerAuthentication
      include ReviewsFeature

      before_action :require_reviews_enabled!
      before_action :authenticate_customer!

      # GET /api/v1/account/reviews
      def index
        reviews, meta = paginate(
          current_customer.reviews.includes(:product, :images).recent
        )
        render_success(ReviewSerializer.collection(reviews), meta: meta)
      end

      # GET /api/v1/account/reviews/pending
      def pending
        reviewed_ids = current_customer.reviews.select(:product_id)
        items = OrderItem.joins(:order, :product_variant)
                         .where(orders: { customer_id: current_customer.id, status: Review::PURCHASED_STATUSES })
                         .where.not(product_variants: { product_id: reviewed_ids })
                         .includes(order: [], product_variant: { product: :product_images })
                         .order("orders.id DESC")

        seen = {}
        pending = items.filter_map do |item|
          product = item.product_variant&.product
          next if product.nil? || seen[product.id]

          seen[product.id] = true
          {
            product_id: product.id,
            name: product.name,
            slug: product.slug,
            image: product.primary_image&.source_url,
            order_id: item.order_id,
            order_number: item.order.order_number
          }
        end

        render_success(pending)
      end
    end
  end
end
