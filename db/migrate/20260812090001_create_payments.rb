# frozen_string_literal: true

# One row per Razorpay order attempt. `status` tracks the payment lifecycle
# independently of Order#status (an order can have more than one payment
# attempt if the shopper retries after a failure).
class CreatePayments < ActiveRecord::Migration[8.1]
  def change
    create_table :payments do |t|
      t.references :order, null: false, foreign_key: true
      t.string :razorpay_order_id, null: false
      t.string :razorpay_payment_id
      t.string :razorpay_signature
      t.integer :amount_cents, null: false
      t.string :currency, null: false, default: "INR"
      t.integer :status, null: false, default: 0
      t.jsonb :raw_payload
      t.timestamps
    end
    add_index :payments, :razorpay_order_id, unique: true
    add_index :payments, :razorpay_payment_id, unique: true
  end
end
