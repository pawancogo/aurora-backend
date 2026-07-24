# frozen_string_literal: true

class SiteSetting < ApplicationRecord
  VALUE_TYPES = %w[string number boolean json].freeze

  validates :key, presence: true, uniqueness: true, format: { with: /\A[a-z0-9_.]+\z/ }
  validates :value_type, inclusion: { in: VALUE_TYPES }
  validates :category, presence: true

  scope :publicly_readable, -> { where(public_read: true) }

  # Flattens a relation into a { key => value } map.
  def self.to_map(scope = all)
    scope.each_with_object({}) { |setting, map| map[setting.key] = setting.value }
  end

  # Typed value for a key (jsonb → native Ruby type), or `default` if unset.
  # Resilient to a missing table (e.g. before migrate) so boot never breaks.
  def self.get(key, default = nil)
    setting = find_by(key: key)
    setting ? setting.value : default
  rescue ActiveRecord::StatementInvalid
    default
  end
end
