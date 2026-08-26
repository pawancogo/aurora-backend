# frozen_string_literal: true

class ProductAnswer < ApplicationRecord
  class Error < StandardError; end

  MIN_BODY = 10

  belongs_to :question, class_name: "ProductQuestion", foreign_key: :product_question_id, inverse_of: :answers
  belongs_to :customer, optional: true
  belongs_to :admin_user, optional: true

  has_paper_trail

  enum :status, { pending: 0, published: 1, hidden: 2 }, validate: true

  validates :body, presence: true, length: { minimum: MIN_BODY, maximum: 2000 }
  validate :author_present

  def from_store?
    admin_user_id.present?
  end

  def publish!
    raise Error, "This answer is already published." if published?

    update!(status: :published)
  end

  def hide!
    raise Error, "This answer is already hidden." if hidden?

    update!(status: :hidden)
  end

  def author_name
    return "Aurora" if from_store?

    first = customer&.first_name.to_s.strip
    last = customer&.last_name.to_s.strip
    return "A customer" if first.blank?

    last.present? ? "#{first} #{last[0]}." : first
  end

  private

  def author_present
    return if customer_id.present? || admin_user_id.present?

    errors.add(:base, "An answer needs a customer or a staff author.")
  end
end
