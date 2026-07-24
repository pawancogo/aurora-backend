# frozen_string_literal: true

module Api
  module V1
    module Customer
      class SessionsController < Api::V1::BaseController
        include AuthResponses

        # POST /api/v1/customer/auth/login
        def create
          customer = Auth::AuthenticateCustomer.new(
            email: params[:email], password: params[:password]
          ).call
          tokens = Auth::IssueTokenPair.new(customer, **request_meta).call
          render_token_pair(:customer, CustomerSerializer.new(customer).as_json, tokens)
        rescue Auth::AuthenticateCustomer::UnconfirmedError => e
          render_error(code: "email_unconfirmed", message: e.message, status: :forbidden)
        rescue Auth::AuthenticateCustomer::AuthenticationError => e
          render_error(code: "invalid_credentials", message: e.message, status: :unauthorized)
        end

        # POST /api/v1/customer/auth/refresh
        def refresh
          rotation = Auth::RotateRefreshToken.new(
            params[:refresh_token], owner_class: ::Customer, **request_meta
          ).call
          render_token_pair(:customer, CustomerSerializer.new(rotation.owner).as_json, rotation.tokens)
        rescue Auth::RotateRefreshToken::InvalidToken => e
          render_error(code: "invalid_refresh_token", message: e.message, status: :unauthorized)
        end

        # POST /api/v1/customer/auth/logout
        def destroy
          digest = TokenDigest.digest(params[:refresh_token].to_s)
          RefreshToken.active.where(owner_type: "Customer").find_by(token_digest: digest)&.revoke!
          render_success({ message: "Signed out." })
        end
      end
    end
  end
end
