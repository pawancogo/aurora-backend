# frozen_string_literal: true

module Api
  module V1
    # Base class for all v1 customer API controllers.
    # Wires in the response envelope, error handling, and pagination.
    # (Authorization is permission-key RBAC via AdminUser#can? / the auth concerns.)
    class BaseController < ApplicationController
      include ApiResponders
      include ApiErrorHandling
      include Paginatable
    end
  end
end
