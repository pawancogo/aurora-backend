# frozen_string_literal: true

class AddressSerializer
  def initialize(address)
    @address = address
  end

  def as_json(*)
    {
      id: @address.id,
      address_type: @address.address_type,
      is_default: @address.is_default,
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
