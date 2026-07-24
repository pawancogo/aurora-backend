# frozen_string_literal: true

class AdminUserRole < ApplicationRecord
  belongs_to :admin_user
  belongs_to :role

  validates :admin_user_id, uniqueness: { scope: :role_id }
end
