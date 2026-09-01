# frozen_string_literal: true

module Admin
  # Order list/detail + fulfillment actions: advance an order one step
  # through Order::FULFILLMENT_SEQUENCE (which also writes a shipment event),
  # enter carrier/tracking/packing notes, log out-for-delivery, cancel/reject
  # (staff get more leeway than shoppers — see Order::ADMIN_CANCELLABLE_STATES),
  # or manually refund a captured payment left over from a cancellation. No
  # free-form status picker. Post-placement address change is out of scope.
  class OrdersController < BaseController
    before_action -> { require_permission!("orders.read") }, only: %i[index show export]
    before_action -> { require_permission!("orders.manage") }, only: %i[advance cancel update_shipment create_shipment_event]
    before_action -> { require_permission!("payments.manage") }, only: %i[refund]

    def index
      result = Order.search(params, scope: filtered_scope)
      @facets = result.facets
      @orders = result.records
    end

    def export
      result = Order.search(params, scope: filtered_scope.includes(:customer), paginate: false)
      send_csv("orders", %w[order_number status customer_email total_rupees placed_at]) do |csv|
        result.records.limit(EXPORT_LIMIT).each do |order|
          csv << [
            order.order_number, order.status, order.customer.email,
            format("%.2f", order.total), order.placed_at&.iso8601
          ]
        end
      end
    end

    def show
      @order = Order.includes(:customer, :order_items, :order_addresses, :payments, :return_requests, shipment: { events: :admin_user }).find(params[:id])
    end

    def advance
      order = Order.find(params[:id])

      if order.advance!(admin_user: current_admin_user, delivery_notes: params[:delivery_notes])
        redirect_to admin_order_path(order), notice: "Order marked as #{order.status.humanize}."
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

    def update_shipment
      order = Order.find(params[:id])
      unless order.can_manage_shipment?
        redirect_to admin_order_path(order), alert: "This order isn't in fulfillment yet."
        return
      end

      order.ensure_shipment!.apply_details!(shipment_params)
      redirect_to admin_order_path(order), notice: "Shipment details saved."
    rescue ActiveRecord::RecordInvalid => e
      redirect_to admin_order_path(order), alert: e.record.errors.full_messages.to_sentence
    end

    def create_shipment_event
      order = Order.find(params[:id])
      unless order.can_manage_shipment?
        redirect_to admin_order_path(order), alert: "This order isn't in fulfillment yet."
        return
      end

      event_type = params[:event_type].to_s
      unless %w[out_for_delivery note].include?(event_type)
        redirect_to admin_order_path(order), alert: "Unknown event type."
        return
      end

      description = params[:description].presence
      description ||= "Out for delivery" if event_type == "out_for_delivery"

      order.ensure_shipment!.events.create!(
        event_type: event_type,
        description: description,
        occurred_at: Time.current,
        admin_user: current_admin_user
      )
      redirect_to admin_order_path(order), notice: "Delivery event added."
    rescue ActiveRecord::RecordInvalid => e
      redirect_to admin_order_path(order), alert: e.record.errors.full_messages.to_sentence
    end

    private

    def shipment_params
      params.require(:shipment).permit(:carrier_name, :tracking_number, :packing_notes)
    end

    def filtered_scope
      scope = Order.includes(:customer, :order_items, :payments).order(placed_at: :desc)
      scope = scope.where(id: Payment.refund_pending.select(:order_id)) if params[:refund_pending].present?
      scope = scope.where(status: %w[confirmed accepted ready_to_ship]) if params[:fulfillment].present?
      scope
    end
  end
end
