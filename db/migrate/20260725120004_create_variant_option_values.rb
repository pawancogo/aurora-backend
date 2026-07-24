# frozen_string_literal: true

# Join: which attribute values make up a variant (e.g. {Color: Red, Size: M}).
# The set of values is what makes a variant unique within its product.
class CreateVariantOptionValues < ActiveRecord::Migration[8.1]
  def change
    create_table :variant_option_values do |t|
      t.references :product_variant, null: false, foreign_key: true
      t.references :attribute_value, null: false, foreign_key: true
      t.timestamps
    end
    add_index :variant_option_values, %i[product_variant_id attribute_value_id],
              unique: true, name: "index_variant_option_values_uniqueness"
  end
end
