# frozen_string_literal: true

class AddCarrierFieldsToOrders < ActiveRecord::Migration[8.1]
  def change
    add_column :orders, :carrier_name, :string
    add_column :orders, :tracking_number, :string
  end
end
