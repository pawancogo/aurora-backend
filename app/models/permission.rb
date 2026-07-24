# frozen_string_literal: true

class Permission < ApplicationRecord
  include SearchManager

  search_manager on: %i[key name description]
  has_paper_trail

  has_many :role_permissions, dependent: :destroy
  has_many :roles, through: :role_permissions

  validates :key, presence: true, uniqueness: true, format: { with: /\A[a-z0-9_.]+\z/ }
  validates :name, presence: true
end
