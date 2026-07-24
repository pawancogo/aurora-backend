# frozen_string_literal: true

# Immutable ledger of every inventory change: a signed quantity, a reason, an
# optional note, and who did it. On-hand reasons move `on_hand`; reservation/
# release reasons move `reserved`.
class CreateStockMovements < ActiveRecord::Migration[8.1]
  def change
    create_table :stock_movements do |t|
      t.references :inventory_item, null: false, foreign_key: true
      t.integer :quantity, null: false           # signed delta
      t.integer :reason, null: false, default: 0  # enum
      t.string  :note
      t.bigint  :admin_user_id                    # actor (nullable; nullified on admin delete)
      t.datetime :created_at, null: false
    end
    add_index :stock_movements, %i[inventory_item_id created_at]
    add_index :stock_movements, :admin_user_id
    add_foreign_key :stock_movements, :admin_users, on_delete: :nullify
  end
end
