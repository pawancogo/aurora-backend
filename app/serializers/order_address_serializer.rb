# frozen_string_literal: true

# Immutable address snapshot on an order.
class OrderAddressSerializer
  def initialize(address)
    @address = address
  end

  def as_json(*)
    {
      full_name: @address.full_name,
      phone: @address.phone,
      line1: @address.line1,
      line2: @address.line2,
      city: @address.city,
      state: @address.state,
      postal_code: @address.postal_code,
      country: @address.country
    }
  end
end
