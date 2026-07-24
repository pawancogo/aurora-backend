# frozen_string_literal: true

module Api
  module V1
    module Admin
      class MeController < Api::V1::BaseController
        include AdminAuthentication

        before_action :authenticate_admin!

        # GET /api/v1/admin/auth/me
        def show
          render_success({ admin_user: AdminUserSerializer.new(current_admin_user).as_json })
        end
      end
    end
  end
end
