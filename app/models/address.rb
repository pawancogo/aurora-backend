# frozen_string_literal: true

# A customer's saved address book entry — reusable across future orders,
# unlike OrderAddress (a one-off snapshot captured at checkout). Exactly one
# address per customer is ever `is_default` at a time.
class Address < ApplicationRecord
  belongs_to :customer

  enum :address_type, { home: 0, office: 1, other: 2 }, default: 0

  validates :full_name, :phone, :line1, :city, :state, :postal_code, :country, presence: true
  validate :within_max_per_customer, on: :create

  before_save :demote_other_defaults, if: :will_save_change_to_is_default?
  after_destroy :promote_next_default, if: :is_default?

  def self.max_per_customer
    SiteSetting.get("addresses.max_per_customer", 10).to_i
  end

  private

  def within_max_per_customer
    return if customer.nil?

    limit = self.class.max_per_customer
    return if customer.addresses.count < limit

    errors.add(:base, "You can save up to #{limit} addresses. Delete one before adding another.")
  end

  def demote_other_defaults
    return unless is_default?

    customer.addresses.where.not(id: id).update_all(is_default: false) # rubocop:disable Rails/SkipsModelValidations
  end

  def promote_next_default
    customer.addresses.order(updated_at: :desc).first&.update!(is_default: true)
  end
end
