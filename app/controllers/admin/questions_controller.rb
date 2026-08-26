# frozen_string_literal: true

module Admin
  class QuestionsController < BaseController
    before_action -> { require_permission!("reviews.read") }, only: %i[index show]
    before_action -> { require_permission!("reviews.manage") }, only: %i[publish hide answer]
    before_action :set_question, only: %i[show publish hide answer]

    def index
      scope = ProductQuestion.includes(:customer, :product).recent
      result = ProductQuestion.search(params, scope: scope)
      @facets = result.facets
      @questions = result.records
    end

    def show
    end

    def publish
      @question.publish!
      redirect_to admin_question_path(@question), notice: "Question published."
    rescue ProductQuestion::Error => e
      redirect_to admin_question_path(@question), alert: e.message
    end

    def hide
      @question.hide!
      redirect_to admin_question_path(@question), notice: "Question hidden."
    rescue ProductQuestion::Error => e
      redirect_to admin_question_path(@question), alert: e.message
    end

    def answer
      @question.answer_as_store!(admin_user: current_admin_user, body: params[:body])
      redirect_to admin_question_path(@question), notice: "Store answer posted."
    rescue ProductQuestion::Error => e
      redirect_to admin_question_path(@question), alert: e.message
    end

    private

    def set_question
      @question = ProductQuestion.includes(:customer, :product, answers: [ :customer, :admin_user ]).find(params[:id])
    end
  end
end
