# frozen_string_literal: true

class AddRefundFieldsToPayments < ActiveRecord::Migration[8.1]
  def change
    add_column :payments, :razorpay_refund_id, :string
    add_column :payments, :refunded_at, :datetime
  end
end
