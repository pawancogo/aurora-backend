# frozen_string_literal: true

class CreateTaxClasses < ActiveRecord::Migration[8.1]
  def change
    create_table :tax_classes do |t|
      t.string :name, null: false
      t.decimal :rate, precision: 5, scale: 2, null: false, default: "0.0"
      t.string :hsn_code

      t.timestamps
    end

    add_index :tax_classes, :name, unique: true
  end
end
