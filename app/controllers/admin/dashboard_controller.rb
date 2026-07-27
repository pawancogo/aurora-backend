# frozen_string_literal: true

module Admin
  class DashboardController < BaseController
    # GET /admin (root) and /admin/dashboard
    def show
      @stats = [
        { label: "Customers", value: Customer.kept.count, permission: "customers.read" },
        { label: "Admin users", value: AdminUser.kept.count, permission: "users.read" },
        { label: "Roles", value: Role.count, permission: "roles.read" },
        { label: "Categories", value: Category.kept.count, permission: "categories.read" },
        { label: "Feature flags", value: FeatureFlag.count, permission: "settings.read" }
      ]
    end
  end
end
