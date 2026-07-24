# frozen_string_literal: true

class CreateCustomers < ActiveRecord::Migration[8.1]
  def change
    create_table :customers do |t|
      t.string :email, null: false
      t.string :password_digest, null: false
      t.string :first_name
      t.string :last_name
      t.string :phone
      t.string :status, null: false, default: "active"
      t.datetime :confirmed_at
      t.string :confirmation_token_digest
      t.datetime :confirmation_sent_at
      t.string :reset_password_token_digest
      t.datetime :reset_password_sent_at
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :customers, :email, unique: true
    add_index :customers, :confirmation_token_digest
    add_index :customers, :reset_password_token_digest
    add_index :customers, :deleted_at
  end
end
