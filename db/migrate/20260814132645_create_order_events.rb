# frozen_string_literal: true

class CreateOrderEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :order_events do |t|
      t.references :order, null: false, foreign_key: true
      t.string :description, null: false
      t.datetime :occurred_at, null: false
      t.timestamps
    end
  end
end
