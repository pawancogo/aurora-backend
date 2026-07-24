# frozen_string_literal: true

class RefreshToken < ApplicationRecord
  belongs_to :owner, polymorphic: true

  scope :active, -> { where(revoked_at: nil).where(expires_at: Time.current..) }

  def active?
    revoked_at.nil? && expires_at.future?
  end

  def revoke!
    update!(revoked_at: Time.current) unless revoked_at
  end
end
