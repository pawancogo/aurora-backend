# frozen_string_literal: true

# A tracked delivery sprint on the roadmap, editable from the admin portal —
# the live replacement for the static PROJECT_STATE.md sprint write-ups.
class Sprint < ApplicationRecord
  has_many :sprint_features, -> { order(:position, :id) }, dependent: :destroy, inverse_of: :sprint

  enum :status, { planned: 0, in_progress: 1, completed: 2 }, default: 0

  validates :number, presence: true, uniqueness: true
  validates :title, presence: true

  scope :ordered, -> { order(:number) }
end
