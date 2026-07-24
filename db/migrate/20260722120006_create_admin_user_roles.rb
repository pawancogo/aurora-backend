# frozen_string_literal: true

class CreateAdminUserRoles < ActiveRecord::Migration[8.1]
  def change
    create_table :admin_user_roles do |t|
      t.references :admin_user, null: false, foreign_key: true
      t.references :role, null: false, foreign_key: true

      t.timestamps
    end

    add_index :admin_user_roles, %i[admin_user_id role_id], unique: true
  end
end
