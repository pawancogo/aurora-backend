# frozen_string_literal: true

class ProductImageSerializer
  def initialize(image)
    @image = image
  end

  def as_json(*)
    value = @image.attribute_value
    {
      id: @image.id,
      url: @image.source_url,
      alt: @image.alt_text,
      position: @image.position,
      primary: @image.primary,
      # When bound to an option value, the storefront swaps to these images as
      # that option is selected. All three are null for a shared image.
      attribute_code: value&.product_attribute&.code,
      value_code: value&.code,
      value: value&.value
    }
  end
end
