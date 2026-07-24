# frozen_string_literal: true

class ProductImageSerializer
  def initialize(image)
    @image = image
  end

  def as_json(*)
    {
      id: @image.id,
      url: @image.source_url,
      alt: @image.alt_text,
      position: @image.position,
      primary: @image.primary
    }
  end
end
