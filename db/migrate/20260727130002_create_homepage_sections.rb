# frozen_string_literal: true

# Configurable homepage blocks. `section_type` selects the block (hero,
# product_rail, category_grid, rich_text, promo); `config` (jsonb) holds
# type-specific settings so new block types need no schema change.
class CreateHomepageSections < ActiveRecord::Migration[8.1]
  def change
    create_table :homepage_sections do |t|
      t.string  :section_type, null: false
      t.string  :title
      t.string  :subtitle
      t.jsonb   :config, null: false, default: {}
      t.integer :position, null: false, default: 0
      t.boolean :visible, null: false, default: true
      t.datetime :starts_at
      t.datetime :ends_at
      t.timestamps
    end
    add_index :homepage_sections, %i[position]
    add_index :homepage_sections, :visible
  end
end
