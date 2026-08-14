# frozen_string_literal: true

# A customer's saved address book entry — reusable across future orders,
# unlike OrderAddress (a one-off snapshot captured at checkout). Exactly one
# address per customer is ever `is_default` at a time.
class Address < ApplicationRecord
  belongs_to :customer

  enum :address_type, { home: 0, office: 1, other: 2 }, default: 0

  validates :full_name, :phone, :line1, :city, :state, :postal_code, :country, presence: true

  before_save :demote_other_defaults, if: :will_save_change_to_is_default?
  after_destroy :promote_next_default, if: :is_default?

  private

  def demote_other_defaults
    return unless is_default?

    customer.addresses.where.not(id: id).update_all(is_default: false) # rubocop:disable Rails/SkipsModelValidations
  end

  def promote_next_default
    customer.addresses.order(updated_at: :desc).first&.update!(is_default: true)
  end
end
