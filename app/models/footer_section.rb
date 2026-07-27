# frozen_string_literal: true

# A footer link column: a heading plus an ordered list of { label, url } links.
class FooterSection < ApplicationRecord
  has_paper_trail

  validates :heading, presence: true

  scope :visible, -> { where(visible: true) }
  scope :ordered, -> { order(:position, :id) }

  # Normalised links: array of { "label" => …, "url" => … }, dropping blanks.
  def link_items
    Array(links).filter_map do |link|
      next unless link.is_a?(Hash)

      label = link["label"].presence || link[:label]
      url = link["url"].presence || link[:url]
      { "label" => label, "url" => url } if label.present? && url.present?
    end
  end
end
