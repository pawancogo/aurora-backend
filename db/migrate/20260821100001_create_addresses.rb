# frozen_string_literal: true

# Customer address book (saved shipping addresses). Separate from
# order_addresses, which remain immutable snapshots captured at checkout.
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

    add_index :addresses, :customer_id, unique: true,
              where: "is_default = TRUE",
              name: "index_addresses_one_default_per_customer"

    reversible do |dir|
      dir.up do
        execute <<~SQL
          INSERT INTO site_settings (key, value, value_type, category, description, public_read, created_at, updated_at)
          VALUES (
            'addresses.max_per_customer',
            '10'::jsonb,
            'number',
            'addresses',
            'Maximum saved addresses a customer can keep in their address book',
            TRUE,
            NOW(),
            NOW()
          )
          ON CONFLICT (key) DO NOTHING
        SQL
      end
    end
  end
end
