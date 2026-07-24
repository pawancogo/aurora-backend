# frozen_string_literal: true

# Free-form descriptive specs shown on the PDP (e.g. "Material: Cotton"),
# optionally grouped ("Display", "General") and ordered.
class CreateProductSpecifications < ActiveRecord::Migration[8.1]
  def change
    create_table :product_specifications do |t|
      t.references :product, null: false, foreign_key: true
      t.string  :name, null: false
      t.string  :value, null: false
      t.string  :spec_group
      t.integer :position, null: false, default: 0
      t.timestamps
    end
  end
end
