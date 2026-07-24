# frozen_string_literal: true

class BrandSerializer
  def initialize(brand)
    @brand = brand
  end

  def as_json(*)
    {
      id: @brand.id,
      name: @brand.name,
      slug: @brand.slug,
      description: @brand.description,
      logo_url: @brand.logo_url,
      meta_title: @brand.meta_title,
      meta_description: @brand.meta_description
    }
  end
end
