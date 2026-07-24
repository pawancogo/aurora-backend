# frozen_string_literal: true

class NavigationItem < ApplicationRecord
  LINK_TYPES = %w[internal external].freeze

  has_paper_trail

  belongs_to :parent, class_name: "NavigationItem", optional: true
  has_many :children,
           class_name: "NavigationItem",
           foreign_key: :parent_id,
           inverse_of: :parent,
           dependent: :destroy

  validates :label, presence: true
  validates :location, presence: true
  validates :link_type, inclusion: { in: LINK_TYPES }
  validates :position, numericality: { only_integer: true }
  validate :parent_not_self

  scope :roots, -> { where(parent_id: nil) }
  scope :visible, -> { where(visible: true) }
  scope :ordered, -> { order(:position, :id) }
  scope :for_location, ->(location) { where(location: location) }
  scope :live, lambda {
    now = Time.current
    where("starts_at IS NULL OR starts_at <= :now", now: now)
      .where("ends_at IS NULL OR ends_at >= :now", now: now)
  }

  after_commit :bust_navigation_cache

  def live?(at = Time.current)
    (starts_at.nil? || starts_at <= at) && (ends_at.nil? || ends_at >= at)
  end

  private

  def parent_not_self
    errors.add(:parent_id, "cannot be itself") if parent_id.present? && parent_id == id
  end

  def bust_navigation_cache
    Navigation::TreeCache.clear!
  end
end
