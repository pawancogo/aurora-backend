# frozen_string_literal: true

class CreateAddresses < ActiveRecord::Migration[8.1]
  def change
    create_table :addresses do |t|
      t.references :customer, null: false, foreign_key: true
      t.integer :address_type, null: false, default: 0
      t.boolean :is_default, null: false, default: false
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
    add_index :addresses, %i[customer_id is_default]
  end
end
