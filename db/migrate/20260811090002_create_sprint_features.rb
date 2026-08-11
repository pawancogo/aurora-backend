# frozen_string_literal: true

# A single feature/task delivered within a sprint. `description` holds
# sanitized HTML authored via the admin rich-text editor.
class CreateSprintFeatures < ActiveRecord::Migration[8.1]
  def change
    create_table :sprint_features do |t|
      t.references :sprint, null: false, foreign_key: true
      t.integer :area, null: false, default: 0
      t.string :title, null: false
      t.text :description
      t.integer :position, null: false, default: 0
      t.timestamps
    end
  end
end
