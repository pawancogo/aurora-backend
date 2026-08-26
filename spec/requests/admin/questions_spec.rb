# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin questions", type: :request do
  def sign_in_admin(admin, password = "password1234")
    post "/admin/login", params: { email: admin.email, password: password }
  end

  it "publishes a question, answers as the store, and publishes a customer answer" do
    sign_in_admin(create(:admin_user, :super_admin, password: "password1234"))
    question = create(:product_question, body: "Will you restock the navy colour?")
    customer_answer = create(:product_answer, question: question, body: "I hope they restock it soon enough.")

    patch "/admin/questions/#{question.id}/publish"
    expect(question.reload).to be_published

    post "/admin/questions/#{question.id}/answers", params: { body: "Navy is due back next month." }
    expect(question.answers.published.where.not(admin_user_id: nil)).to exist

    patch "/admin/answers/#{customer_answer.id}/publish"
    expect(customer_answer.reload).to be_published
  end

  it "forbids the list without reviews.read" do
    sign_in_admin(create(:admin_user, password: "password1234"))

    get "/admin/questions"

    expect(response).to redirect_to("/admin")
  end
end
