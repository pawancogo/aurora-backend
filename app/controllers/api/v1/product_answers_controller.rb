# frozen_string_literal: true

module Api
  module V1
    class ProductAnswersController < BaseController
      include CustomerAuthentication
      include ReviewsFeature

      before_action :require_reviews_enabled!
      before_action :authenticate_customer!

      rescue_from ProductQuestion::Error, ProductAnswer::Error do |error|
        render_error(code: "answer_not_allowed", message: error.message)
      end

      # POST /api/v1/questions/:question_id/answers
      def create
        question = ProductQuestion.published.find(params[:question_id])
        answer = question.answer_as_customer!(customer: current_customer, body: params[:body])
        render_success(
          {
            id: answer.id,
            body: answer.body,
            status: answer.status,
            from_store: false,
            author_name: answer.author_name,
            created_at: answer.created_at
          },
          status: :created
        )
      end
    end
  end
end
