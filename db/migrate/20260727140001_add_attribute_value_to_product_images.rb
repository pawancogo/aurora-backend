# frozen_string_literal: true

# Optionally bind an image to a variant option value (e.g. the colour "Blue")
# so the storefront can swap the gallery when that option is selected. NULL =
# a shared product-level image.
class AddAttributeValueToProductImages < ActiveRecord::Migration[8.1]
  def change
    add_reference :product_images, :attribute_value, null: true, foreign_key: true
  end
end
