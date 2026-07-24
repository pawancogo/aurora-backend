# frozen_string_literal: true

class CreateProductImages < ActiveRecord::Migration[8.1]
  def change
    create_table :product_images do |t|
      t.references :product, null: false, foreign_key: true
      t.string :source_url, null: false
      t.string :alt_text
      t.integer :position, null: false, default: 0
      t.boolean :primary, null: false, default: false

      t.timestamps
    end

    add_index :product_images, %i[product_id position]
  end
end
