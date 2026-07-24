# frozen_string_literal: true

# Auto-generates a unique, URL-safe slug from #name when one isn't provided.
module Sluggable
  extend ActiveSupport::Concern

  included do
    before_validation :generate_slug, if: -> { slug.blank? && name.present? }
    validates :slug, presence: true, uniqueness: true,
                     format: { with: /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/ }
  end

  private

  def generate_slug
    base = name.parameterize
    candidate = base
    suffix = 2
    while self.class.where.not(id: id).exists?(slug: candidate)
      candidate = "#{base}-#{suffix}"
      suffix += 1
    end
    self.slug = candidate
  end
end
