# frozen_string_literal: true

module Admin
  # Order list/detail + fulfillment actions: advance an order one step
  # through Order::FULFILLMENT_SEQUENCE, cancel/reject it outright (staff get
  # more leeway than shoppers — see Order::ADMIN_CANCELLABLE_STATES), or
  # manually refund a captured payment left over from a cancellation. No
  # free-form status picker — address-change workflow, etc. still lands in a
  # later sprint.
  class OrdersController < BaseController
    before_action -> { require_permission!("orders.read") }, only: %i[index show]
    before_action -> { require_permission!("orders.manage") }, only: %i[advance cancel]
    before_action -> { require_permission!("payments.manage") }, only: %i[refund]

    def index
      scope = Order.includes(:customer, :order_items, :payments).order(placed_at: :desc)
      scope = scope.where(id: Payment.refund_pending.select(:order_id)) if params[:refund_pending].present?
      result = Order.search(params, scope: scope)
      @facets = result.facets
      @orders = result.records
    end

    def show
      @order = Order.includes(:customer, :order_items, :order_addresses, :payments).find(params[:id])
    end

    def advance
      order = Order.find(params[:id])
      next_status = order.next_status

      if next_status
        order.update!(status: next_status)
        redirect_to admin_order_path(order), notice: "Order marked as #{next_status.humanize}."
      else
        redirect_to admin_order_path(order), alert: "This order can't be advanced any further."
      end
    end

    def cancel
      order = Order.find(params[:id])

      if order.admin_cancel!
        redirect_to admin_order_path(order), notice: "Order cancelled."
      else
        redirect_to admin_order_path(order), alert: "This order can no longer be cancelled — it's already shipped."
      end
    end

    def refund
      order = Order.find(params[:id])
      payment = order.refund_payment

      if payment.nil?
        redirect_to admin_order_path(order), alert: "No refund is pending for this order."
        return
      end

      Payments::Refund.new(payment: payment).call
      redirect_to admin_order_path(order), notice: "Refund processed."
    rescue Payments::Refund::Error => e
      redirect_to admin_order_path(order), alert: e.message
    end
  end
end
