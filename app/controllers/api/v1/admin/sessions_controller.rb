# frozen_string_literal: true

module Api
  module V1
    module Admin
      class SessionsController < Api::V1::BaseController
        include AuthResponses

        # POST /api/v1/admin/auth/login
        def create
          admin = Auth::AuthenticateAdmin.new(
            email: params[:email], password: params[:password]
          ).call
          tokens = Auth::IssueTokenPair.new(admin, **request_meta).call
          render_token_pair(:admin_user, AdminUserSerializer.new(admin).as_json, tokens)
        rescue Auth::AuthenticateAdmin::AuthenticationError => e
          render_error(code: "invalid_credentials", message: e.message, status: :unauthorized)
        end

        # POST /api/v1/admin/auth/refresh
        def refresh
          rotation = Auth::RotateRefreshToken.new(
            params[:refresh_token], owner_class: ::AdminUser, **request_meta
          ).call
          render_token_pair(:admin_user, AdminUserSerializer.new(rotation.owner).as_json, rotation.tokens)
        rescue Auth::RotateRefreshToken::InvalidToken => e
          render_error(code: "invalid_refresh_token", message: e.message, status: :unauthorized)
        end

        # POST /api/v1/admin/auth/logout
        def destroy
          digest = TokenDigest.digest(params[:refresh_token].to_s)
          RefreshToken.active.where(owner_type: "AdminUser").find_by(token_digest: digest)&.revoke!
          render_success({ message: "Signed out." })
        end
      end
    end
  end
end
