# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1 product reviews", type: :request do
  def data
    response.parsed_body["data"]
  end

  def auth_headers_for(customer)
    post "/api/v1/customer/auth/login", params: { email: customer.email, password: "password123" }, as: :json
    access = response.parsed_body.dig("data", "tokens", "access_token")
    { "Authorization" => "Bearer #{access}" }
  end

  def enable_reviews!
    FeatureFlag.find_or_create_by!(key: "reviews") { |flag| flag.name = "Product Reviews" }
               .update!(enabled: true)
  end

  def delivered_purchase(customer:, product:)
    order = create(:order, customer: customer, status: :delivered)
    create(:order_item, order: order, product_variant: product.master_variant)
    order
  end

  before { enable_reviews! }

  it "lists only published reviews, with sort and photo filter" do
    product = create(:product)
    published = create(:review, :published, :with_photo, product: product, rating: 5, title: "Visible")
    create(:review, product: product, rating: 2, title: "Pending")
    create(:review, :published, product: create(:product), title: "Other product")

    get "/api/v1/products/#{product.slug}/reviews", params: { sort: "rating_desc", with_photos: true }

    expect(response).to have_http_status(:ok)
    expect(data.map { |row| row["id"] }).to eq([ published.id ])
    expect(data.first["verified_purchase"]).to be true
    expect(data.first["images"].length).to eq(1)
    expect(response.parsed_body.dig("meta", "rating_count")).to eq(1)
  end

  it "lets a verified purchaser submit a review" do
    customer = create(:customer)
    product = create(:product)
    delivered_purchase(customer: customer, product: product)

    post "/api/v1/products/#{product.slug}/reviews",
         params: {
           rating: 4,
           title: "Nice fit",
           body: "The fabric feels premium and washing has not changed the colour.",
           image_urls: [ "https://cdn.example.com/me.jpg" ]
         },
         headers: auth_headers_for(customer), as: :json

    expect(response).to have_http_status(:created)
    expect(data["status"]).to eq("pending")
    expect(data["verified_purchase"]).to be true
    expect(data["images"].first["url"]).to include("me.jpg")
  end

  it "rejects a review when the customer never received the product" do
    customer = create(:customer)
    product = create(:product)

    post "/api/v1/products/#{product.slug}/reviews",
         params: { rating: 5, body: "I have not bought this but I still want to review it here." },
         headers: auth_headers_for(customer), as: :json

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body.dig("error", "code")).to eq("review_not_allowed")
  end

  it "toggles a helpful vote on a published review" do
    customer = create(:customer)
    review = create(:review, :published)

    post "/api/v1/reviews/#{review.id}/vote", headers: auth_headers_for(customer), as: :json
    expect(response).to have_http_status(:ok)
    expect(data["helpful_count"]).to eq(1)
    expect(data["voted"]).to be true

    post "/api/v1/reviews/#{review.id}/vote", headers: auth_headers_for(customer), as: :json
    expect(data["helpful_count"]).to eq(0)
    expect(data["voted"]).to be false
  end

  it "lists pending products to review from delivered orders" do
    customer = create(:customer)
    product = create(:product, name: "Linen Shirt")
    delivered_purchase(customer: customer, product: product)
    already = create(:product, name: "Already Reviewed")
    delivered_purchase(customer: customer, product: already)
    create(:review, customer: customer, product: already)

    get "/api/v1/account/reviews/pending", headers: auth_headers_for(customer)

    expect(data.map { |row| row["name"] }).to eq([ "Linen Shirt" ])
    expect(data.first["slug"]).to eq(product.slug)
  end

  it "404s when the reviews flag is off" do
    FeatureFlag.find_by!(key: "reviews").update!(enabled: false)
    product = create(:product)

    get "/api/v1/products/#{product.slug}/reviews"
    expect(response).to have_http_status(:not_found)
    expect(response.parsed_body.dig("error", "code")).to eq("reviews_disabled")
  end

  it "includes rating fields on the product detail payload" do
    product = create(:product)
    create(:review, :published, product: product, rating: 5)

    get "/api/v1/products/#{product.slug}"

    expect(response.parsed_body.dig("data", "rating_avg")).to eq(5.0)
    expect(response.parsed_body.dig("data", "rating_count")).to eq(1)
  end
end
