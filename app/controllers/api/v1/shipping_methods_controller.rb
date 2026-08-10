# frozen_string_literal: true

module Api
  module V1
    # Public: shipping options offered at checkout.
    class ShippingMethodsController < BaseController
      # GET /api/v1/shipping_methods
      def index
        methods = ShippingMethod.active.ordered
        render_success(methods.map { |method| ShippingMethodSerializer.new(method).as_json })
      end
    end
  end
end
