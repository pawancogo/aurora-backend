# frozen_string_literal: true

# Footer link columns. Each section is a heading + an ordered list of links
# (jsonb array of { label, url }).
class CreateFooterSections < ActiveRecord::Migration[8.1]
  def change
    create_table :footer_sections do |t|
      t.string  :heading, null: false
      t.jsonb   :links, null: false, default: []
      t.integer :position, null: false, default: 0
      t.boolean :visible, null: false, default: true
      t.timestamps
    end
    add_index :footer_sections, :position
  end
end
