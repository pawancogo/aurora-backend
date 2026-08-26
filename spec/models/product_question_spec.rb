# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProductQuestion do
  it "starts pending when a customer asks" do
    question = described_class.ask!(
      product: create(:product),
      customer: create(:customer),
      body: "Does this run true to size?"
    )

    expect(question).to be_pending
  end

  it "lets staff answer as the store immediately as published" do
    question = create(:product_question, :published)
    admin = create(:admin_user)

    answer = question.answer_as_store!(admin_user: admin, body: "Yes — order your usual size.")

    expect(answer).to be_published
    expect(answer).to be_from_store
  end

  it "keeps a customer answer pending until staff publish it" do
    question = create(:product_question, :published)

    answer = question.answer_as_customer!(
      customer: create(:customer),
      body: "I ordered M and it fit just as expected."
    )

    expect(answer).to be_pending
    expect(answer).not_to be_from_store
  end

  it "does not accept a customer answer on a pending question" do
    question = create(:product_question)

    expect {
      question.answer_as_customer!(customer: create(:customer), body: "I think it runs large actually.")
    }.to raise_error(ProductQuestion::Error, /published question/i)
  end
end
