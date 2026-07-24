# frozen_string_literal: true

FactoryBot.define do
  factory :product_attribute do
    sequence(:name) { |n| "Attribute #{n}" }
    sequence(:code) { |n| "attribute_#{n}" }
    filterable { true }
    searchable { false }

    trait :color do
      name { "Color" }
      code { "color" }
    end

    trait :size do
      name { "Size" }
      code { "size" }
    end
  end

  factory :attribute_value do
    product_attribute
    sequence(:value) { |n| "Value #{n}" }
    sequence(:code) { |n| "value_#{n}" }
  end
end
