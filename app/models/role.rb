# frozen_string_literal: true

class Role < ApplicationRecord
  include SearchManager

  search_manager on: %i[name key description]

  has_many :role_permissions, dependent: :destroy
  has_many :permissions, through: :role_permissions
  has_many :admin_user_roles, dependent: :destroy
  has_many :admin_users, through: :admin_user_roles

  validates :key, presence: true, uniqueness: true, format: { with: /\A[a-z0-9_]+\z/ }
  validates :name, presence: true
end
