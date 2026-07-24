# frozen_string_literal: true

class Customer < ApplicationRecord
  include Discardable
  include SearchManager

  search_manager on: %i[email first_name last_name phone], aggs_on: %i[status]

  has_secure_password

  has_many :refresh_tokens, as: :owner, dependent: :destroy

  before_validation :normalize_email

  validates :email,
            presence: true,
            uniqueness: { case_sensitive: false },
            format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8 }, allow_nil: true
  validates :status, inclusion: { in: %w[active inactive] }

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
end
