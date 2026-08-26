# frozen_string_literal: true

class Customer < ApplicationRecord
  include Discardable
  include SearchManager

  search_manager on: %i[email first_name last_name phone], aggs_on: %i[status]
  has_paper_trail skip: %i[password_digest confirmation_token_digest reset_password_token_digest]

  has_secure_password

  has_many :refresh_tokens, as: :owner, dependent: :destroy
  has_many :wishlist_items, dependent: :destroy
  has_many :wishlisted_products, through: :wishlist_items, source: :product
  has_many :addresses, dependent: :destroy
  has_many :orders, dependent: :restrict_with_error
  has_many :return_requests, dependent: :restrict_with_error
  has_many :reviews, dependent: :restrict_with_error
  has_many :product_questions, dependent: :restrict_with_error
  has_many :review_votes, dependent: :destroy
  has_many :notifications, dependent: :destroy
  has_many :notification_preferences, dependent: :destroy

  before_validation :normalize_email
  before_validation :ensure_unsubscribe_token

  validates :email,
            presence: true,
            uniqueness: { case_sensitive: false },
            format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8 }, allow_nil: true
  validates :status, inclusion: { in: %w[active inactive] }
  validates :unsubscribe_token, presence: true, uniqueness: true

  def confirmed?
    confirmed_at.present?
  end

  def active_for_auth?
    status == "active" && kept?
  end

  def full_name
    [ first_name, last_name ].compact_blank.join(" ").presence
  end

  private

  def normalize_email
    self.email = email.to_s.strip.downcase.presence
  end

  def ensure_unsubscribe_token
    self.unsubscribe_token ||= SecureRandom.urlsafe_base64(24)
  end
end
