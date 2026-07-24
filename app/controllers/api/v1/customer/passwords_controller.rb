# frozen_string_literal: true

module Api
  module V1
    module Customer
      class PasswordsController < Api::V1::BaseController
        # POST /api/v1/customer/auth/forgot-password
        def create
          Auth::RequestPasswordReset.new(email: params[:email]).call
          render_success({ message: "If an account exists for that email, a reset link has been sent." })
        end

        # POST /api/v1/customer/auth/reset-password
        def update
          Auth::ResetPassword.new(token: params[:token], password: params[:password]).call
          render_success({ message: "Your password has been updated. Please sign in." })
        rescue Auth::ResetPassword::InvalidToken => e
          render_error(code: "invalid_token", message: e.message, status: :unprocessable_content)
        end
      end
    end
  end
end
