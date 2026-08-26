# frozen_string_literal: true

# Customer RMA: a return request on a delivered order, with line items to
# restock. Distinct from the CMS /p/returns policy page.
class CreateReturnRequests < ActiveRecord::Migration[8.1]
  def change
    create_table :return_requests do |t|
      t.references :order, null: false, foreign_key: true
      t.references :customer, null: false, foreign_key: true
      t.string :rma_number, null: false
      t.integer :status, null: false, default: 0
      t.integer :resolution, null: false, default: 0
      t.string :reason, null: false
      t.text :admin_notes
      t.datetime :decided_at
      t.datetime :received_at
      t.datetime :completed_at
      t.timestamps
    end
    add_index :return_requests, :rma_number, unique: true
    add_index :return_requests, :status

    create_table :return_items do |t|
      t.references :return_request, null: false, foreign_key: true
      t.references :order_item, null: false, foreign_key: true
      t.integer :quantity, null: false
      t.boolean :restocked, null: false, default: false
      t.timestamps
    end
    add_index :return_items, %i[return_request_id order_item_id], unique: true

    reversible do |dir|
      dir.up do
        execute <<~SQL
          INSERT INTO site_settings (key, value, value_type, category, description, public_read, created_at, updated_at)
          VALUES (
            'returns.window_days',
            '7'::jsonb,
            'number',
            'returns',
            'Days after delivery during which a shopper can request a return',
            TRUE,
            NOW(),
            NOW()
          )
          ON CONFLICT (key) DO NOTHING
        SQL
      end
    end
  end
end
