# frozen_string_literal: true

module Api
  module V1
    module Customer
      class MeController < Api::V1::BaseController
        include CustomerAuthentication

        before_action :authenticate_customer!

        # GET /api/v1/customer/auth/me
        def show
          render_success({ customer: CustomerSerializer.new(current_customer).as_json })
        end
      end
    end
  end
end
