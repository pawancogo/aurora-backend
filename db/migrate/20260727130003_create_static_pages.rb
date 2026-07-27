# frozen_string_literal: true

# CMS static pages (About, Contact, Privacy, Terms, Shipping, Returns, …),
# addressed by slug, with per-page SEO.
class CreateStaticPages < ActiveRecord::Migration[8.1]
  def change
    create_table :static_pages do |t|
      t.string  :slug, null: false
      t.string  :title, null: false
      t.text    :body
      t.boolean :published, null: false, default: false
      t.string  :meta_title
      t.string  :meta_description
      t.integer :position, null: false, default: 0
      t.timestamps
    end
    add_index :static_pages, :slug, unique: true
  end
end
