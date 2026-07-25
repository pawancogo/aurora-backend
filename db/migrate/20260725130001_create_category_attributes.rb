# frozen_string_literal: true

# Links which variant attributes apply to which category, so a product's variant
# form only offers the relevant options (e.g. Shirts → Color + Apparel Size;
# Footwear → Color + Shoe Size). Inherited down the category tree.
class CreateCategoryAttributes < ActiveRecord::Migration[8.1]
  def change
    create_table :category_attributes do |t|
      t.references :category, null: false, foreign_key: true
      t.references :product_attribute, null: false, foreign_key: true
      t.integer :position, null: false, default: 0
      t.timestamps
    end
    add_index :category_attributes, %i[category_id product_attribute_id],
              unique: true, name: "index_category_attributes_uniqueness"
  end
end
