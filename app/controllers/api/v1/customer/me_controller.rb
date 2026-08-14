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

        # PATCH /api/v1/customer/auth/me { customer: { first_name, last_name, phone } }
        def update
          current_customer.update!(profile_params)
          render_success({ customer: CustomerSerializer.new(current_customer).as_json })
        end

        private

        def profile_params
          params.require(:customer).permit(:first_name, :last_name, :phone)
        end
      end
    end
  end
end
