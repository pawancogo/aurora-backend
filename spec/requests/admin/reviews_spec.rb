# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin reviews", type: :request do
  def sign_in_admin(admin, password = "password1234")
    post "/admin/login", params: { email: admin.email, password: password }
  end

  it "lists reviews for an admin with reviews.read" do
    sign_in_admin(create(:admin_user, :super_admin, password: "password1234"))
    review = create(:review, title: "Queue item")

    get "/admin/reviews"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(review.product.name)
  end

  it "publishes, hides, and responds" do
    sign_in_admin(create(:admin_user, :super_admin, password: "password1234"))
    review = create(:review, rating: 4)

    patch "/admin/reviews/#{review.id}/publish"
    expect(review.reload).to be_published
    expect(review.product.reload.rating_count).to eq(1)

    patch "/admin/reviews/#{review.id}/respond", params: { admin_response: "Glad it worked out." }
    expect(review.reload.admin_response).to eq("Glad it worked out.")

    patch "/admin/reviews/#{review.id}/hide"
    expect(review.reload).to be_hidden
    expect(review.product.reload.rating_count).to eq(0)
  end

  it "forbids the list without reviews.read" do
    sign_in_admin(create(:admin_user, password: "password1234"))

    get "/admin/reviews"

    expect(response).to redirect_to("/admin")
  end
end
