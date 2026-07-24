# frozen_string_literal: true

# Lightweight soft-delete: sets a `deleted_at` timestamp instead of destroying rows.
module Discardable
  extend ActiveSupport::Concern

  included do
    scope :kept, -> { where(deleted_at: nil) }
    scope :discarded, -> { where.not(deleted_at: nil) }
  end

  def discard!
    update!(deleted_at: Time.current) unless discarded?
  end

  def discarded?
    deleted_at.present?
  end

  def kept?
    !discarded?
  end
end
