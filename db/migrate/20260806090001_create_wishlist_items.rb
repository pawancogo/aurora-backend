# frozen_string_literal: true

# A customer's saved-for-later products (product-level, not variant-level —
# size/colour is chosen again at add-to-cart time).
class CreateWishlistItems < ActiveRecord::Migration[8.1]
  def change
    create_table :wishlist_items do |t|
      t.references :customer, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.timestamps
    end
    add_index :wishlist_items, %i[customer_id product_id], unique: true
  end
end
