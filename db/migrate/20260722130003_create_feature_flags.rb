# frozen_string_literal: true

class CreateFeatureFlags < ActiveRecord::Migration[8.1]
  def change
    create_table :feature_flags do |t|
      t.string :key, null: false
      t.string :name, null: false
      t.string :description
      t.boolean :enabled, null: false, default: false

      t.timestamps
    end

    add_index :feature_flags, :key, unique: true
  end
end
