# frozen_string_literal: true

class NavigationItemSerializer
  def initialize(item, children: nil)
    @item = item
    @children = children
  end

  def as_json(*)
    {
      id: @item.id,
      parent_id: @item.parent_id,
      location: @item.location,
      label: @item.label,
      slug: @item.slug,
      url: @item.url,
      link_type: @item.link_type,
      icon: @item.icon,
      image_url: @item.image_url,
      position: @item.position,
      visible: @item.visible,
      open_in_new_tab: @item.open_in_new_tab,
      starts_at: @item.starts_at,
      ends_at: @item.ends_at,
      meta_title: @item.meta_title,
      meta_description: @item.meta_description,
      children: @children || []
    }
  end
end
