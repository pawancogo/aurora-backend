# frozen_string_literal: true

module Api
  module V1
    module Admin
      class RolesController < Api::V1::BaseController
        include AdminAuthentication

        before_action { authorize_permission!("roles.read") }

        # GET /api/v1/admin/roles
        def index
          roles = Role.includes(:permissions).order(:name)
          render_success(roles.map { |role| RoleSerializer.new(role).as_json })
        end
      end
    end
  end
end
