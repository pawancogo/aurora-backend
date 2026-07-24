# frozen_string_literal: true

# Join row tying a variant to one of its attribute values.
class VariantOptionValue < ApplicationRecord
  belongs_to :product_variant, inverse_of: :variant_option_values
  belongs_to :attribute_value

  validates :attribute_value_id, uniqueness: { scope: :product_variant_id }
end
