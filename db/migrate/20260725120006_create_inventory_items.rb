# frozen_string_literal: true

# Stock for a single variant. `available = on_hand - reserved`.
# One row per variant.
class CreateInventoryItems < ActiveRecord::Migration[8.1]
  def change
    create_table :inventory_items do |t|
      t.references :product_variant, null: false, foreign_key: true, index: { unique: true }
      t.integer :on_hand, null: false, default: 0
      t.integer :reserved, null: false, default: 0
      t.integer :low_stock_threshold, null: false, default: 0  # 0 = alerts off
      t.boolean :backorderable, null: false, default: false
      t.timestamps
    end
  end
end
