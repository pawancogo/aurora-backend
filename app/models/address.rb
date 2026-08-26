# frozen_string_literal: true

# A saved address in a customer's address book. Independent of OrderAddress,
# which is an immutable snapshot taken at checkout.
class Address < ApplicationRecord
  DEFAULT_MAX_PER_CUSTOMER = 10

  belongs_to :customer

  has_paper_trail

  enum :address_type, { home: 0, office: 1, other: 2 }, validate: true

  validates :full_name, :phone, :line1, :city, :state, :postal_code, :country, presence: true
  validates :phone, length: { minimum: 6 }
  validate :within_max_per_customer, on: :create

  before_validation :blank_to_nil_line2
  before_validation :assign_default_if_first, on: :create
  before_save :clear_other_defaults, if: :is_default?
  after_destroy :promote_fallback_default

  def self.max_per_customer
    limit = SiteSetting.get("addresses.max_per_customer", DEFAULT_MAX_PER_CUSTOMER).to_i
    limit.positive? ? limit : DEFAULT_MAX_PER_CUSTOMER
  end

  def make_default!
    transaction do
      customer.addresses.where.not(id: id).update_all(is_default: false)
      update!(is_default: true)
    end
  end

  private

  def blank_to_nil_line2
    self.line2 = line2.presence
  end

  def assign_default_if_first
    return if customer.blank?

    self.is_default = true if customer.addresses.where.not(id: id).none?
  end

  def clear_other_defaults
    return if customer.blank?

    scope = customer.addresses.where(is_default: true)
    scope = scope.where.not(id: id) if id.present?
    scope.update_all(is_default: false)
  end

  def within_max_per_customer
    return if customer.blank?

    limit = self.class.max_per_customer
    return if customer.addresses.count < limit

    errors.add(:base, "You've reached the maximum of #{limit} saved addresses.")
  end

  def promote_fallback_default
    return unless is_default

    customer.addresses.order(:id).first&.update_columns(is_default: true)
  end
end
