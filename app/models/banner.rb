# frozen_string_literal: true

# A merchandising banner. `placement` selects where it renders: hero carousel,
# a promo strip, or the header announcement bar. Visible + schedulable.
class Banner < ApplicationRecord
  include Schedulable
  has_paper_trail

  enum :placement, { hero: "hero", promo: "promo", announcement: "announcement" }, default: "hero"

  validates :placement, presence: true
  validates :title, presence: true, if: -> { announcement? }
end
