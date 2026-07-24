# frozen_string_literal: true

module Api
  module V1
    module Admin
      class PermissionsController < Api::V1::BaseController
        include AdminAuthentication

        before_action { authorize_permission!("permissions.read") }

        # GET /api/v1/admin/permissions
        def index
          permissions = Permission.order(:key)
          render_success(permissions.map { |permission| PermissionSerializer.new(permission).as_json })
        end
      end
    end
  end
end
