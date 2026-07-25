# frozen_string_literal: true

module InventoryHelper
  # A coloured availability badge for an inventory item.
  def stock_badge(item)
    return content_tag(:span, "—", class: "muted") unless item

    if item.available <= 0
      content_tag(:span, item.backorderable? ? "Backorder" : "Out of stock", class: "stock-badge out")
    elsif item.low_stock?
      content_tag(:span, "Low · #{item.available}", class: "stock-badge low")
    else
      content_tag(:span, item.available, class: "stock-badge ok")
    end
  end

  # Chips for a variant's option combination ("Default" for the master).
  def variant_option_chips(variant)
    return content_tag(:span, "Default", class: "muted") if variant.is_master?

    chips = variant.attribute_values.map do |value|
      content_tag(:span, "#{value.product_attribute&.name}: #{value.value}", class: "opt-chip")
    end
    content_tag(:span, safe_join(chips), class: "opt-chips")
  end
end
