# frozen_string_literal: true

# Directed product-to-product links (related / recommended / cross-sell / up-sell)
# powering the PDP "you may also like" rails.
class CreateProductRelations < ActiveRecord::Migration[8.1]
  def change
    create_table :product_relations do |t|
      t.references :product, null: false, foreign_key: true
      t.bigint  :related_product_id, null: false
      t.integer :relation_kind, null: false, default: 0  # enum
      t.integer :position, null: false, default: 0
      t.timestamps
    end
    add_index :product_relations, :related_product_id
    add_index :product_relations, %i[product_id related_product_id relation_kind],
              unique: true, name: "index_product_relations_uniqueness"
    add_foreign_key :product_relations, :products, column: :related_product_id
  end
end
