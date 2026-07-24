# frozen_string_literal: true

class CreateProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :products do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.string :sku, null: false
      t.references :brand, foreign_key: true, null: true
      t.references :category, foreign_key: true, null: true
      t.references :tax_class, foreign_key: true, null: true

      t.text :description
      t.jsonb :highlights, null: false, default: []

      t.integer :status, null: false, default: 0 # draft
      t.boolean :featured, null: false, default: false
      t.boolean :new_arrival, null: false, default: false
      t.boolean :best_seller, null: false, default: false

      t.integer :price_cents, null: false, default: 0
      t.integer :mrp_cents, null: false, default: 0
      t.string :currency, null: false, default: "INR"

      t.integer :weight_grams
      t.jsonb :dimensions, null: false, default: {}
      t.string :warranty

      t.string :meta_title
      t.string :meta_description
      t.string :search_keywords

      t.datetime :published_at
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :products, :slug, unique: true
    add_index :products, :sku, unique: true
    add_index :products, :status
    add_index :products, :featured
    add_index :products, :new_arrival
    add_index :products, :best_seller
    add_index :products, :published_at
    add_index :products, :deleted_at
  end
end
