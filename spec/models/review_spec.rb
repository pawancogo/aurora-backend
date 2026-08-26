# frozen_string_literal: true

require "rails_helper"

RSpec.describe Review do
  def delivered_purchase(customer:, product:)
    order = create(:order, customer: customer, status: :delivered)
    create(:order_item, order: order, product_variant: product.master_variant)
    order
  end

  describe ".submit!" do
    it "creates a pending verified-purchase review for a delivered order" do
      customer = create(:customer)
      product = create(:product)
      delivered_purchase(customer: customer, product: product)

      review = described_class.submit!(
        product: product,
        customer: customer,
        rating: 5,
        title: "Love it",
        body: "Soft fabric and the colour matches the photos online.",
        image_urls: [ "https://cdn.example.com/pic.jpg" ]
      )

      expect(review).to be_pending
      expect(review).to be_verified_purchase
      expect(review.images.map(&:url)).to eq([ "https://cdn.example.com/pic.jpg" ])
      expect(product.reload.rating_count).to eq(0)
    end

    it "rejects a customer who has not received the product" do
      customer = create(:customer)
      product = create(:product)
      order = create(:order, customer: customer, status: :shipped)
      create(:order_item, order: order, product_variant: product.master_variant)

      expect {
        described_class.submit!(
          product: product,
          customer: customer,
          rating: 4,
          body: "Looks good so far but it is still on the way to me."
        )
      }.to raise_error(Review::Error, /delivered order/i)
    end

    it "rejects a second review of the same product" do
      customer = create(:customer)
      product = create(:product)
      delivered_purchase(customer: customer, product: product)
      described_class.submit!(
        product: product,
        customer: customer,
        rating: 5,
        body: "First review with enough detail to pass the minimum length."
      )

      expect {
        described_class.submit!(
          product: product,
          customer: customer,
          rating: 3,
          body: "Trying to post a second review of the same product here."
        )
      }.to raise_error(Review::Error, /already reviewed/i)
    end
  end

  describe "#publish!" do
    it "recalculates the product's cached average and distribution" do
      product = create(:product)
      create(:review, :published, product: product, rating: 5)
      pending = create(:review, product: product, rating: 3)

      pending.publish!

      product.reload
      expect(product.rating_count).to eq(2)
      expect(product.rating_avg.to_f).to eq(4.0)
      expect(product.rating_distribution).to include("5" => 1, "3" => 1, "1" => 0)
    end
  end

  describe "#hide!" do
    it "drops a published review from the product average" do
      product = create(:product)
      review = create(:review, :published, product: product, rating: 5)

      review.hide!

      expect(product.reload.rating_count).to eq(0)
      expect(product.rating_avg.to_f).to eq(0)
    end
  end

  describe "#toggle_vote!" do
    it "adds then removes a helpful vote and keeps helpful_count in sync" do
      review = create(:review, :published)
      voter = create(:customer)

      review.toggle_vote!(voter)
      expect(review.reload.helpful_count).to eq(1)

      review.toggle_vote!(voter)
      expect(review.reload.helpful_count).to eq(0)
    end
  end
end
