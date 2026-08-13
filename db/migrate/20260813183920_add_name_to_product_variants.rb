# frozen_string_literal: true

# nil -> falls back to the parent product's name (see ProductVariant#display_name).
class AddNameToProductVariants < ActiveRecord::Migration[8.1]
  def change
    add_column :product_variants, :name, :string
  end
end
