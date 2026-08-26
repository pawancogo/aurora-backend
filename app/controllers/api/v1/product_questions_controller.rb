# frozen_string_literal: true

module Api
  module V1
    class ProductQuestionsController < BaseController
      include CustomerAuthentication
      include ReviewsFeature

      before_action :require_reviews_enabled!
      before_action :authenticate_customer!, only: :create

      rescue_from ProductQuestion::Error do |error|
        render_error(code: "question_not_allowed", message: error.message)
      end

      # GET /api/v1/products/:product_id/questions
      def index
        product = find_live_product!
        scope = visible_questions(product).includes(:customer, answers: [ :customer, :admin_user ]).recent
        questions, meta = paginate(scope)
        render_success(ProductQuestionSerializer.collection(questions), meta: meta)
      end

      # POST /api/v1/products/:product_id/questions
      def create
        product = find_live_product!
        question = ProductQuestion.ask!(product: product, customer: current_customer, body: params[:body])
        render_success(ProductQuestionSerializer.new(question).as_json, status: :created)
      end

      private

      def visible_questions(product)
        published = product.questions.published
        return published unless current_customer

        published.or(product.questions.where(customer: current_customer))
      end
    end
  end
end
