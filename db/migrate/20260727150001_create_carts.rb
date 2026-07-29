# frozen_string_literal: true

# Persistent cart. A cart belongs to a customer once they sign in; before that
# it's a guest cart identified by an opaque `token` (sent via X-Cart-Token).
class CreateCarts < ActiveRecord::Migration[8.1]
  def change
    create_table :carts do |t|
      t.references :customer, null: true, foreign_key: true, index: false
      t.string :token, null: false
      t.timestamps
    end
    add_index :carts, :token, unique: true
    # One cart per customer; guests (NULL customer_id) are unconstrained.
    add_index :carts, :customer_id, unique: true, name: "index_carts_on_customer_id_unique"

    create_table :cart_items do |t|
      t.references :cart, null: false, foreign_key: true
      t.references :product_variant, null: false, foreign_key: true
      t.integer :quantity, null: false, default: 1
      t.timestamps
    end
    add_index :cart_items, %i[cart_id product_variant_id], unique: true
  end
end
