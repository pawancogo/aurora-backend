# frozen_string_literal: true

# A CMS static page (About, Contact, Privacy, …), addressed by slug.
class StaticPage < ApplicationRecord
  include Sluggable # slugs from #name → aliased to title below
  include SearchManager
  has_paper_trail

  alias_attribute :name, :title

  search_manager on: %i[title slug], aggs_on: %i[published]

  validates :title, presence: true

  scope :published, -> { where(published: true) }
  scope :ordered, -> { order(:position, :title) }
end
