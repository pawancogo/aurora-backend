# frozen_string_literal: true

# Visibility + optional scheduling window for CMS content (banners, homepage
# sections, …). A record is "live" when it's visible and the current time falls
# within its [starts_at, ends_at] window (either bound may be nil = open-ended).
# Requires `visible`, `position`, `starts_at`, `ends_at` columns.
module Schedulable
  extend ActiveSupport::Concern

  included do
    scope :visible, -> { where(visible: true) }
    scope :ordered, -> { order(:position, :id) }
    scope :live, lambda {
      now = Time.current
      visible
        .where("starts_at IS NULL OR starts_at <= ?", now)
        .where("ends_at IS NULL OR ends_at >= ?", now)
    }
  end

  def live?
    visible? &&
      (starts_at.nil? || starts_at <= Time.current) &&
      (ends_at.nil? || ends_at >= Time.current)
  end
end
