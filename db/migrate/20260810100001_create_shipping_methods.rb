# frozen_string_literal: true

# Configurable shipping options offered at checkout. No carrier integration —
# just a name, price, and whether it's currently offered.
class CreateShippingMethods < ActiveRecord::Migration[8.1]
  def change
    create_table :shipping_methods do |t|
      t.string :name, null: false
      t.string :description
      t.integer :price_cents, null: false, default: 0
      t.boolean :active, null: false, default: true
      t.integer :position, null: false, default: 0
      t.timestamps
    end
  end
end
