# frozen_string_literal: true

class CreateCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :categories do |t|
      t.references :parent, foreign_key: { to_table: :categories }, null: true
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.string :image_url
      t.integer :position, null: false, default: 0
      t.boolean :visible, null: false, default: true
      t.string :meta_title
      t.string :meta_description
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :categories, :slug, unique: true
    add_index :categories, %i[parent_id position]
    add_index :categories, :visible
    add_index :categories, :deleted_at
  end
end
