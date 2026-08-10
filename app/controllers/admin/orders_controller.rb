# frozen_string_literal: true

module Admin
  # Order list/detail — read-only for this sprint; placement/fulfillment
  # tooling (status updates, address-change workflow) lands in a later sprint.
  class OrdersController < BaseController
    before_action -> { require_permission!("orders.read") }, only: %i[index show]

    def index
      result = Order.search(params, scope: Order.includes(:customer, :order_items).order(placed_at: :desc))
      @facets = result.facets
      @orders = result.records
    end

    def show
      @order = Order.includes(:customer, :order_items, :order_addresses).find(params[:id])
    end
  end
end
