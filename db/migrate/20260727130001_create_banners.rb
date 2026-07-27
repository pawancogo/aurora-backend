# frozen_string_literal: true

# Merchandising banners: hero carousel slides, promo strips, and the header
# announcement bar (distinguished by `placement`). Visible + schedulable.
class CreateBanners < ActiveRecord::Migration[8.1]
  def change
    create_table :banners do |t|
      t.string  :placement, null: false, default: "hero" # hero | promo | announcement
      t.string  :title
      t.string  :subtitle
      t.string  :image_url
      t.string  :mobile_image_url
      t.string  :link_url
      t.string  :cta_label
      t.string  :alt_text
      t.integer :position, null: false, default: 0
      t.boolean :visible, null: false, default: true
      t.datetime :starts_at
      t.datetime :ends_at
      t.timestamps
    end
    add_index :banners, %i[placement position]
    add_index :banners, :visible
  end
end
