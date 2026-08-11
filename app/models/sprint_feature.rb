# frozen_string_literal: true

# A single feature/task delivered within a Sprint.
#
# Two separate HTML bodies, both authored via the admin rich-text editor,
# for two different audiences:
#   description             — plain-language, what it does (PMs/stakeholders).
#   technical_description   — implementation detail, how it works (engineers).
# Both are sanitized on save (and again on render, belt-and-suspenders) since
# they're arbitrary user-authored markup.
class SprintFeature < ApplicationRecord
  ALLOWED_TAGS = %w[p br strong b em i u h2 h3 h4 ul ol li a blockquote code].freeze
  ALLOWED_ATTRIBUTES = %w[href].freeze

  belongs_to :sprint, inverse_of: :sprint_features

  enum :area, { backend: 0, frontend: 1, admin: 2, database: 3, testing: 4, other: 5 }, default: 0

  validates :title, presence: true

  before_save :sanitize_description
  before_save :sanitize_technical_description

  scope :ordered, -> { order(:position, :id) }

  private

  def sanitize_description
    self.description = sanitize_html(description)
  end

  def sanitize_technical_description
    self.technical_description = sanitize_html(technical_description)
  end

  def sanitize_html(html)
    ActionController::Base.helpers.sanitize(html, tags: ALLOWED_TAGS, attributes: ALLOWED_ATTRIBUTES)
  end
end
