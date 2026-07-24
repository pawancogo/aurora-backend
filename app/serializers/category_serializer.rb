# frozen_string_literal: true

class CategorySerializer
  def initialize(category, children: nil)
    @category = category
    @children = children
  end

  def as_json(*)
    {
      id: @category.id,
      parent_id: @category.parent_id,
      name: @category.name,
      slug: @category.slug,
      description: @category.description,
      image_url: @category.image_url,
      position: @category.position,
      visible: @category.visible,
      meta_title: @category.meta_title,
      meta_description: @category.meta_description,
      children: @children || []
    }
  end
end
