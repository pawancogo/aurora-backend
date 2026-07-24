# frozen_string_literal: true

module Api
  module V1
    module Customer
      class EmailVerificationsController < Api::V1::BaseController
        include AuthResponses

        # POST /api/v1/customer/auth/verify-email
        # On success the customer is auto-logged-in (tokens returned).
        def create
          customer = Auth::VerifyEmail.new(params[:token]).call
          tokens = Auth::IssueTokenPair.new(customer, **request_meta).call
          render_token_pair(:customer, CustomerSerializer.new(customer).as_json, tokens)
        rescue Auth::VerifyEmail::InvalidToken => e
          render_error(code: "invalid_token", message: e.message, status: :unprocessable_content)
        end

        # POST /api/v1/customer/auth/resend-verification
        def resend
          Auth::ResendVerification.new(email: params[:email]).call
          render_success({ message: "If your email needs verification, a new link has been sent." })
        end
      end
    end
  end
end
