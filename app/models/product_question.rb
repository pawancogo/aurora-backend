# frozen_string_literal: true

# A shopper question on a product. Starts pending; staff publish or hide.
# Answers come from other customers (pending until published) or from staff
# (published immediately as the store response).
class ProductQuestion < ApplicationRecord
  include SearchManager

  search_manager on: %i[body], aggs_on: %i[status]

  class Error < StandardError; end

  MIN_BODY = 10

  belongs_to :product
  belongs_to :customer
  has_many :answers, -> { order(:id) }, class_name: "ProductAnswer", dependent: :destroy, inverse_of: :question

  has_paper_trail

  enum :status, { pending: 0, published: 1, hidden: 2 }, validate: true

  validates :body, presence: true, length: { minimum: MIN_BODY, maximum: 1000 }

  scope :recent, -> { order(id: :desc) }
  scope :visible, -> { published }

  def self.ask!(product:, customer:, body:)
    create!(product: product, customer: customer, body: body.to_s.strip, status: :pending)
  end

  def publish!
    raise Error, "This question is already published." if published?

    update!(status: :published)
  end

  def hide!
    raise Error, "This question is already hidden." if hidden?

    update!(status: :hidden)
  end

  def answer_as_store!(admin_user:, body:)
    text = body.to_s.strip
    raise Error, "Answer can't be blank." if text.blank?

    answers.create!(admin_user: admin_user, body: text, status: :published)
  end

  def answer_as_customer!(customer:, body:)
    raise Error, "Only a published question can be answered." unless published?

    text = body.to_s.strip
    raise Error, "Answer can't be blank." if text.length < ProductAnswer::MIN_BODY

    answers.create!(customer: customer, body: text, status: :pending)
  end

  def asker_name
    first = customer.first_name.to_s.strip
    last = customer.last_name.to_s.strip
    return "A customer" if first.blank?

    last.present? ? "#{first} #{last[0]}." : first
  end
end
