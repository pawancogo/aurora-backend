# frozen_string_literal: true

class FeatureFlag < ApplicationRecord
  validates :key, presence: true, uniqueness: true, format: { with: /\A[a-z0-9_.]+\z/ }
  validates :name, presence: true

  def self.to_map(scope = all)
    scope.each_with_object({}) { |flag, map| map[flag.key] = flag.enabled }
  end
end
