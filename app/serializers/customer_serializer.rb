# frozen_string_literal: true

class CustomerSerializer
  def initialize(customer)
    @customer = customer
  end

  def as_json(*)
    {
      id: @customer.id,
      email: @customer.email,
      first_name: @customer.first_name,
      last_name: @customer.last_name,
      full_name: @customer.full_name,
      phone: @customer.phone,
      confirmed: @customer.confirmed?,
      status: @customer.status,
      created_at: @customer.created_at
    }
  end
end
