# frozen_string_literal: true

class CreateBrands < ActiveRecord::Migration[8.1]
  def change
    create_table :brands do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.string :logo_url
      t.string :meta_title
      t.string :meta_description
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :brands, :slug, unique: true
    add_index :brands, :deleted_at
  end
end
