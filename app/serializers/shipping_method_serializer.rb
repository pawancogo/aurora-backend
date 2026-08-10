# frozen_string_literal: true

class ShippingMethodSerializer
  def initialize(shipping_method)
    @shipping_method = shipping_method
  end

  def as_json(*)
    {
      id: @shipping_method.id,
      name: @shipping_method.name,
      description: @shipping_method.description,
      price: @shipping_method.price
    }
  end
end
