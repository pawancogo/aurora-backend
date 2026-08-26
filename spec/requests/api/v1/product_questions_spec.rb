# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1 product questions", type: :request do
  def data
    response.parsed_body["data"]
  end

  def auth_headers_for(customer)
    post "/api/v1/customer/auth/login", params: { email: customer.email, password: "password123" }, as: :json
    access = response.parsed_body.dig("data", "tokens", "access_token")
    { "Authorization" => "Bearer #{access}" }
  end

  before do
    FeatureFlag.find_or_create_by!(key: "reviews") { |flag| flag.name = "Product Reviews" }
               .update!(enabled: true)
  end

  it "lists published questions with published answers" do
    product = create(:product)
    question = create(:product_question, :published, product: product, body: "Is this machine washable?")
    create(:product_answer, :from_store, question: question)
    create(:product_answer, question: question, body: "I washed mine on cold and it was fine.")
    create(:product_question, product: product, body: "Still waiting to be published here.")

    get "/api/v1/products/#{product.slug}/questions"

    expect(data.length).to eq(1)
    expect(data.first["body"]).to eq("Is this machine washable?")
    expect(data.first["answers"].length).to eq(1)
    expect(data.first["answers"].first["from_store"]).to be true
  end

  it "lets a signed-in customer ask a question that starts pending" do
    customer = create(:customer)
    product = create(:product)

    post "/api/v1/products/#{product.slug}/questions",
         params: { body: "Does the colour fade after a few washes?" },
         headers: auth_headers_for(customer), as: :json

    expect(response).to have_http_status(:created)
    expect(data["status"]).to eq("pending")
  end

  it "lets a customer answer a published question (pending until moderated)" do
    customer = create(:customer)
    question = create(:product_question, :published)

    post "/api/v1/questions/#{question.id}/answers",
         params: { body: "I washed mine twice and the colour held up well." },
         headers: auth_headers_for(customer), as: :json

    expect(response).to have_http_status(:created)
    expect(data["status"]).to eq("pending")
    expect(data["from_store"]).to be false
  end

  it "does not list another customer's pending question" do
    product = create(:product)
    customer = create(:customer)
    create(:product_question, product: product, customer: customer, body: "My unpublished question is here.")
    create(:product_question, product: product, body: "Someone else's unpublished question.")

    get "/api/v1/products/#{product.slug}/questions", headers: auth_headers_for(customer)

    expect(data.map { |row| row["body"] }).to eq([ "My unpublished question is here." ])
  end
end
