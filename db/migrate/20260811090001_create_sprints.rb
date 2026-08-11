# frozen_string_literal: true

# A tracked sprint on the delivery roadmap. Replaces the static PROJECT_STATE.md
# write-ups as the live, editable source of truth — visible/editable from the
# admin portal instead of requiring a repo checkout to read.
class CreateSprints < ActiveRecord::Migration[8.1]
  def change
    create_table :sprints do |t|
      t.integer :number, null: false
      t.string :title, null: false
      t.text :goal
      t.integer :status, null: false, default: 0
      t.string :dependencies
      t.string :estimate
      t.date :started_on
      t.date :completed_on
      t.timestamps
    end
    add_index :sprints, :number, unique: true
  end
end
