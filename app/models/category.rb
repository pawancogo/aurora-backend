# frozen_string_literal: true

class Category < ApplicationRecord
  include Sluggable
  include Discardable
  include SearchManager

  search_manager on: %i[name slug], aggs_on: %i[visible]
  has_paper_trail

  belongs_to :parent, class_name: "Category", optional: true
  has_many :children,
           class_name: "Category",
           foreign_key: :parent_id,
           inverse_of: :parent,
           dependent: :destroy
  has_many :products, dependent: :nullify
  has_many :category_attributes, dependent: :destroy
  has_many :variant_attributes, through: :category_attributes, source: :product_attribute

  validates :name, presence: true
  validate :parent_not_self

  scope :roots, -> { where(parent_id: nil) }
  scope :visible, -> { where(visible: true) }
  scope :ordered, -> { order(:position, :name) }

  # Ordered list of ancestors (root first) — for breadcrumbs.
  def ancestors
    node = parent
    list = []
    while node
      list.unshift(node)
      node = node.parent
    end
    list
  end

  # This category plus all descendant ids — used to include subcategory products.
  def subtree_ids
    ids = [ id ]
    children.each { |child| ids.concat(child.subtree_ids) }
    ids
  end

  private

  def parent_not_self
    errors.add(:parent_id, "cannot be itself") if parent_id.present? && parent_id == id
  end
end
