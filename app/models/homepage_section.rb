# frozen_string_literal: true

# A configurable homepage block. `section_type` picks the renderer; `config`
# (jsonb) carries type-specific settings, e.g.:
#   product_rail  → { "source" => "new_arrival"|"best_seller"|"featured"|"category",
#                     "category_slug" => "men", "limit" => 8 }
#   category_grid → { "limit" => 6 }
#   rich_text     → { "body" => "…" }
#   hero / promo  → { "placement" => "hero" }  (pulls live Banners)
class HomepageSection < ApplicationRecord
  include Schedulable
  has_paper_trail

  SECTION_TYPES = %w[hero product_rail category_grid rich_text promo].freeze

  validates :section_type, presence: true, inclusion: { in: SECTION_TYPES }

  # Convenience readers for the jsonb config (never nil).
  def config_hash
    config.is_a?(Hash) ? config : {}
  end

  def setting(key, default = nil)
    config_hash.fetch(key.to_s, default)
  end
end
