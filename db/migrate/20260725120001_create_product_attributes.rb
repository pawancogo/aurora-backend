# frozen_string_literal: true

# Attribute registry — the metadata-driven definitions (e.g. Color, Size, Storage)
# that both define variants and act as storefront facets.
class CreateProductAttributes < ActiveRecord::Migration[8.1]
  def change
    create_table :product_attributes do |t|
      t.string  :name, null: false
      t.string  :code, null: false           # machine key, e.g. "color"
      t.boolean :filterable, null: false, default: false  # exposed as a storefront facet
      t.boolean :searchable, null: false, default: false
      t.integer :position, null: false, default: 0
      t.timestamps
    end
    add_index :product_attributes, :code, unique: true
  end
end
