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
    before_action -> { require_permission!("orders.manage") },
                  only: %i[advance cancel update_tracking add_event update_shipping_address]
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

    # PATCH /admin/orders/:id/tracking { carrier_name:, tracking_number: }
    def update_tracking
      order = Order.find(params[:id])
      order.update!(tracking_params)
      redirect_to admin_order_path(order), notice: "Tracking details updated."
    end

    # POST /admin/orders/:id/events { description:, occurred_at: }
    def add_event
      order = Order.find(params[:id])
      order.order_events.create!(description: params[:description], occurred_at: params[:occurred_at].presence || Time.current)
      redirect_to admin_order_path(order), notice: "Delivery update added."
    end

    # PATCH /admin/orders/:id/shipping_address { address: { ... } }
    def update_shipping_address
      order = Order.find(params[:id])
      unless order.admin_cancellable?
        redirect_to admin_order_path(order), alert: "This order has already shipped — its address can no longer be changed."
        return
      end

      order.update_shipping_address!(address_params)
      redirect_to admin_order_path(order), notice: "Shipping address updated."
    end

    private

    def tracking_params
      params.permit(:carrier_name, :tracking_number)
    end

    def address_params
      params.require(:address).permit(:full_name, :phone, :line1, :line2, :city, :state, :postal_code, :country)
    end
  end
end
