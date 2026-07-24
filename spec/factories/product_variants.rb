# frozen_string_literal: true

FactoryBot.define do
  factory :product_variant do
    product
    is_master { false }
    active { true }
    # sku auto-generates (HasSku); price/mrp inherit from the product when nil.

    trait :master do
      is_master { true }
    end

    trait :priced do
      price_cents { 1500 }
      mrp_cents { 2500 }
    end
  end

  factory :product_specification do
    product
    sequence(:name) { |n| "Spec #{n}" }
    sequence(:value) { |n| "Value #{n}" }
  end

  factory :variant_option_value do
    product_variant
    attribute_value
  end

  factory :stock_movement do
    inventory_item { create(:product_variant).inventory_item }
    quantity { 5 }
    reason { :restock }
  end

  factory :product_relation do
    product
    related_product factory: %i[product]
    relation_kind { :related }
  end
end
