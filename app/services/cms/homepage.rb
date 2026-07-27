# frozen_string_literal: true

module Cms
  # Composes the public homepage payload: the ordered live sections (each resolved
  # to its data by type), the active announcement, and the footer — in one call.
  class Homepage
    DEFAULT_LIMIT = 8
    MAX_LIMIT = 24

    def as_json
      {
        announcement: announcement_json,
        sections: HomepageSection.live.ordered.map { |section| section_json(section) },
        footer: FooterSection.visible.ordered.map { |f| { heading: f.heading, links: f.link_items } }
      }
    end

    private

    def announcement_json
      banner = Banner.announcement.live.ordered.first
      return nil unless banner

      { title: banner.title, link_url: banner.link_url, cta_label: banner.cta_label }
    end

    def section_json(section)
      {
        id: section.id,
        type: section.section_type,
        title: section.title,
        subtitle: section.subtitle,
        data: section_data(section)
      }
    end

    def section_data(section)
      case section.section_type
      when "hero", "promo"    then { banners: banners_for(section) }
      when "product_rail"     then { products: rail_products(section) }
      when "category_grid"    then { categories: grid_categories(section) }
      when "rich_text"        then { body: section.setting("body").to_s }
      else {}
      end
    end

    def banners_for(section)
      placement = section.setting("placement", section.section_type)
      Banner.where(placement: placement).live.ordered.map do |banner|
        {
          id: banner.id, title: banner.title, subtitle: banner.subtitle,
          image_url: banner.image_url, mobile_image_url: banner.mobile_image_url,
          link_url: banner.link_url, cta_label: banner.cta_label, alt_text: banner.alt_text
        }
      end
    end

    def rail_products(section)
      limit = clamp_limit(section.setting("limit"))
      scope = Product.kept.live.includes(:brand, :product_images)
      scope =
        case section.setting("source")
        when "featured"     then scope.featured
        when "best_seller"  then scope.best_sellers
        when "category"     then in_category(scope, section.setting("category_slug"))
        else scope.new_arrivals # default rail
        end
      scope.order(created_at: :desc).limit(limit).map { |product| ProductListSerializer.new(product).as_json }
    end

    def in_category(scope, slug)
      category = Category.kept.visible.find_by(slug: slug)
      return scope.none unless category

      scope.where(category_id: category.subtree_ids)
    end

    def grid_categories(section)
      limit = clamp_limit(section.setting("limit"), default: 6)
      Category.roots.kept.visible.ordered.limit(limit).map do |category|
        { id: category.id, name: category.name, slug: category.slug, image_url: category.image_url }
      end
    end

    def clamp_limit(value, default: DEFAULT_LIMIT)
      n = value.to_i
      return default unless n.positive?

      [ n, MAX_LIMIT ].min
    end
  end
end
