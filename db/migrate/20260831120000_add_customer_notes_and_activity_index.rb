# frozen_string_literal: true

class AddCustomerNotesAndActivityIndex < ActiveRecord::Migration[8.1]
  def change
    create_table :customer_notes do |t|
      t.references :customer, null: false, foreign_key: true
      t.references :admin_user, null: false, foreign_key: true
      t.text :body, null: false
      t.timestamps
    end
    add_index :customer_notes, [ :customer_id, :id ]

    add_index :versions, :created_at, name: "index_versions_on_created_at"
  end
end
