# frozen_string_literal: true

# Immutable address snapshot captured at checkout — never a foreign key to a
# customer's address book (that book doesn't exist yet; canonical Sprint 8 /
# Customer Profile & Address Book is still pending). Editing/versioning this
# after placement is Sprint 11 (Delivery & Address Change Workflow) territory.
class CreateOrderAddresses < ActiveRecord::Migration[8.1]
  def change
    create_table :order_addresses do |t|
      t.references :order, null: false, foreign_key: true
      t.integer :address_type, null: false, default: 0
      t.string :full_name, null: false
      t.string :phone, null: false
      t.string :line1, null: false
      t.string :line2
      t.string :city, null: false
      t.string :state, null: false
      t.string :postal_code, null: false
      t.string :country, null: false, default: "IN"
      t.timestamps
    end
  end
end
