# frozen_string_literal: true

# A purchasable variation of a product. Every product owns one hidden `master`
# variant (option-less; carries default price + inventory when the product has
# no real options); products with options own one variant per option combination.
# price/mrp are nullable — nil inherits the parent product's price.
class CreateProductVariants < ActiveRecord::Migration[8.1]
  def change
    create_table :product_variants do |t|
      t.references :product, null: false, foreign_key: true
      t.string  :sku, null: false
      t.string  :barcode
      t.integer :price_cents          # nil → inherit product.price_cents
      t.integer :mrp_cents            # nil → inherit product.mrp_cents
      t.integer :position, null: false, default: 0
      t.boolean :active, null: false, default: true
      t.boolean :is_master, null: false, default: false
      t.string  :image_url
      t.timestamps
    end
    add_index :product_variants, :sku, unique: true
    add_index :product_variants, %i[product_id is_master]
  end
end
