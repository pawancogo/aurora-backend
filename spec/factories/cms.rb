# frozen_string_literal: true

FactoryBot.define do
  factory :banner do
    placement { "hero" }
    sequence(:title) { |n| "Banner #{n}" }
    image_url { "https://example.com/banner.jpg" }
    visible { true }

    trait :announcement do
      placement { "announcement" }
      title { "Free shipping this week" }
      link_url { "/products" }
    end

    trait :promo do
      placement { "promo" }
    end

    trait :scheduled_future do
      starts_at { 2.days.from_now }
    end

    trait :expired do
      ends_at { 2.days.ago }
    end

    trait :hidden do
      visible { false }
    end
  end

  factory :homepage_section do
    section_type { "product_rail" }
    sequence(:title) { |n| "Section #{n}" }
    sequence(:position) { |n| n }
    visible { true }
    config { { "source" => "new_arrival", "limit" => 4 } }

    trait :hero do
      section_type { "hero" }
      config { { "placement" => "hero" } }
    end

    trait :rich_text do
      section_type { "rich_text" }
      config { { "body" => "Welcome to Aurora." } }
    end

    trait :category_grid do
      section_type { "category_grid" }
      config { { "limit" => 6 } }
    end

    trait :hidden do
      visible { false }
    end

    trait :scheduled_future do
      starts_at { 2.days.from_now }
    end
  end

  factory :static_page do
    sequence(:title) { |n| "Page #{n}" }
    body { "Some content." }
    published { true }
  end

  factory :footer_section do
    sequence(:heading) { |n| "Column #{n}" }
    links { [ { "label" => "About", "url" => "/p/about" } ] }
    visible { true }
  end
end
