# frozen_string_literal: true

class AdminUser < ApplicationRecord
  include Discardable
  include SearchManager

  search_manager on: %i[email first_name last_name], aggs_on: %i[status]

  has_secure_password

  has_many :admin_user_roles, dependent: :destroy
  has_many :roles, through: :admin_user_roles
  has_many :permissions, -> { distinct }, through: :roles
  has_many :refresh_tokens, as: :owner, dependent: :destroy

  before_validation :normalize_email

  validates :email,
            presence: true,
            uniqueness: { case_sensitive: false },
            format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 10 }, allow_nil: true
  validates :status, inclusion: { in: %w[active inactive] }

  def super_admin?
    roles.exists?(key: "super_admin")
  end

  # Super admins implicitly hold every permission.
  def can?(permission_key)
    super_admin? || permissions.exists?(key: permission_key)
  end

  def permission_keys
    permissions.pluck(:key)
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
