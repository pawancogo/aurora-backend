# frozen_string_literal: true

class CreateNavigationItems < ActiveRecord::Migration[8.1]
  def change
    create_table :navigation_items do |t|
      t.references :parent, foreign_key: { to_table: :navigation_items }, null: true
      t.string :location, null: false, default: "header"
      t.string :label, null: false
      t.string :slug
      t.string :url
      t.string :link_type, null: false, default: "internal"
      t.string :icon
      t.string :image_url
      t.integer :position, null: false, default: 0
      t.boolean :visible, null: false, default: true
      t.boolean :open_in_new_tab, null: false, default: false
      t.datetime :starts_at
      t.datetime :ends_at
      t.string :meta_title
      t.string :meta_description

      t.timestamps
    end

    add_index :navigation_items, %i[location parent_id position]
    add_index :navigation_items, :visible
  end
end
