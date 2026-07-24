# frozen_string_literal: true

# Auto-generates a unique SKU when none is supplied (a manual SKU is still
# honoured). The DB unique index + a uniqueness validation are the final guards;
# this just picks a collision-free candidate up front. Shared by Product and
# ProductVariant.
module HasSku
  extend ActiveSupport::Concern

  included do
    before_validation :generate_sku, if: -> { sku.blank? }
    validates :sku, presence: true, uniqueness: true
  end

  private

  # "<PREFIX>-XXXXXXXX" with a random suffix; retried on the rare collision.
  def generate_sku
    loop do
      candidate = "#{sku_prefix}-#{SecureRandom.alphanumeric(8).upcase}"
      break self.sku = candidate unless self.class.where.not(id: id).exists?(sku: candidate)
    end
  end

  # Overridable per model (Product → "SKU", ProductVariant → "VAR").
  def sku_prefix
    "SKU"
  end
end
