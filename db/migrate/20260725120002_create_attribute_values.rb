# frozen_string_literal: true

# The allowed values for an attribute (e.g. Color → Red/Blue; Size → S/M/L).
# `metadata` carries presentation hints such as a colour swatch hex.
class CreateAttributeValues < ActiveRecord::Migration[8.1]
  def change
    create_table :attribute_values do |t|
      t.references :product_attribute, null: false, foreign_key: true
      t.string  :value, null: false          # display, e.g. "Red"
      t.string  :code, null: false           # machine key, e.g. "red"
      t.integer :position, null: false, default: 0
      t.jsonb   :metadata, null: false, default: {}
      t.timestamps
    end
    add_index :attribute_values, %i[product_attribute_id code], unique: true
  end
end
