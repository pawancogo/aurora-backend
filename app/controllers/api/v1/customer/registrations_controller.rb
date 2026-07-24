# frozen_string_literal: true

module Api
  module V1
    module Customer
      class RegistrationsController < Api::V1::BaseController
        # POST /api/v1/customer/auth/register
        def create
          result = Auth::RegisterCustomer.new(registration_params).call

          render_success({
                           customer: CustomerSerializer.new(result.customer).as_json,
                           message: "Account created. Check your email to verify your address."
                         }, status: :created)
        end

        private

        def registration_params
          params.require(:customer).permit(:email, :password, :first_name, :last_name, :phone)
        end
      end
    end
  end
end
