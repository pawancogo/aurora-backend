# frozen_string_literal: true

# One shipment per order for the manual-delivery flow: carrier/tracking,
# warehouse packing notes, optional delivery notes, and a timeline of events
# (packed, out for delivery, delivered, free-form notes).
class CreateShipments < ActiveRecord::Migration[8.1]
  def change
    create_table :shipments do |t|
      t.references :order, null: false, foreign_key: true, index: { unique: true }
      t.string :carrier_name
      t.string :tracking_number
      t.text :packing_notes
      t.text :delivery_notes
      t.timestamps
    end

    create_table :shipment_events do |t|
      t.references :shipment, null: false, foreign_key: true
      t.integer :event_type, null: false, default: 0
      t.string :description, null: false
      t.datetime :occurred_at, null: false
      t.bigint :admin_user_id
      t.timestamps
    end
    add_index :shipment_events, %i[shipment_id occurred_at]
    add_index :shipment_events, :admin_user_id
    add_foreign_key :shipment_events, :admin_users, on_delete: :nullify
  end
end
