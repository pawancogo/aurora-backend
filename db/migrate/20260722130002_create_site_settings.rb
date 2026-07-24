# frozen_string_literal: true

class CreateSiteSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :site_settings do |t|
      t.string :key, null: false
      t.jsonb :value, null: false, default: {}
      t.string :value_type, null: false, default: "string"
      t.string :category, null: false, default: "general"
      t.string :description
      t.boolean :public_read, null: false, default: false

      t.timestamps
    end

    add_index :site_settings, :key, unique: true
    add_index :site_settings, :category
  end
end
