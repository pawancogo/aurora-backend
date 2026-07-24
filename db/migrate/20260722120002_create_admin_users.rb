# frozen_string_literal: true

class CreateAdminUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :admin_users do |t|
      t.string :email, null: false
      t.string :password_digest, null: false
      t.string :first_name
      t.string :last_name
      t.string :status, null: false, default: "active"
      t.datetime :last_login_at
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :admin_users, :email, unique: true
    add_index :admin_users, :deleted_at
  end
end
