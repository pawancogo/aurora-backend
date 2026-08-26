# frozen_string_literal: true

class ProductQuestionSerializer
  def self.collection(questions)
    questions.map { |question| new(question).as_json }
  end

  def initialize(question)
    @question = question
  end

  def as_json(*)
    {
      id: @question.id,
      body: @question.body,
      status: @question.status,
      asker_name: @question.asker_name,
      created_at: @question.created_at,
      answers: visible_answers.map { |answer| answer_json(answer) }
    }
  end

  private

  def visible_answers
    @question.answers.select(&:published?)
  end

  def answer_json(answer)
    {
      id: answer.id,
      body: answer.body,
      from_store: answer.from_store?,
      author_name: answer.author_name,
      created_at: answer.created_at
    }
  end
end
