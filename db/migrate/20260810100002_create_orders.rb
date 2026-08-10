# frozen_string_literal: true

# A placed order. Money/shipping-method fields are snapshotted at placement
# time (shipping_method_id is kept for convenience/analytics only — the name
# and price that applied live on the order itself).
class CreateOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :orders do |t|
      t.references :customer, null: false, foreign_key: true
      t.references :shipping_method, null: true, foreign_key: true
      t.string :order_number, null: false
      t.integer :status, null: false, default: 0
      t.string :shipping_method_name, null: false
      t.integer :subtotal_cents, null: false
      t.integer :shipping_cents, null: false, default: 0
      t.integer :total_cents, null: false
      t.string :currency, null: false, default: "INR"
      t.datetime :placed_at, null: false
      t.datetime :cancelled_at
      t.timestamps
    end
    add_index :orders, :order_number, unique: true
  end
end
