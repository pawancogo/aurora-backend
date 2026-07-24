# frozen_string_literal: true

class CreateRoles < ActiveRecord::Migration[8.1]
  def change
    create_table :roles do |t|
      t.string :key, null: false
      t.string :name, null: false
      t.string :description
      t.boolean :system, null: false, default: false

      t.timestamps
    end

    add_index :roles, :key, unique: true
  end
end
