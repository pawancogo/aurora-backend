# frozen_string_literal: true

module Admin
  class AnswersController < BaseController
    before_action -> { require_permission!("reviews.manage") }

    def publish
      answer = ProductAnswer.find(params[:id])
      answer.publish!
      redirect_to admin_question_path(answer.question), notice: "Answer published."
    rescue ProductAnswer::Error => e
      redirect_to admin_question_path(answer.question), alert: e.message
    end

    def hide
      answer = ProductAnswer.find(params[:id])
      answer.hide!
      redirect_to admin_question_path(answer.question), notice: "Answer hidden."
    rescue ProductAnswer::Error => e
      redirect_to admin_question_path(answer.question), alert: e.message
    end
  end
end
