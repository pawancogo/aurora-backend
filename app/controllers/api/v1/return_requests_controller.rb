# frozen_string_literal: true

module Api
  module V1
    # Shopper RMAs: list/detail plus create nested under an order.
    class ReturnRequestsController < BaseController
      include CustomerAuthentication

      before_action :authenticate_customer!

      rescue_from ReturnRequest::Error do |error|
        render_error(code: "return_not_allowed", message: error.message)
      end

      # GET /api/v1/return_requests
      def index
        requests, meta = paginate(
          current_customer.return_requests.includes(:order, return_items: :order_item).recent
        )
        render_success(ReturnRequestSerializer.collection(requests), meta: meta)
      end

      # GET /api/v1/return_requests/:id
      def show
        request = current_customer.return_requests.includes(:order, return_items: :order_item).find(params[:id])
        render_success(ReturnRequestSerializer.new(request).as_json)
      end

      # POST /api/v1/orders/:order_id/return_requests
      def create
        order = current_customer.orders.includes(:order_items, :return_requests, shipment: :events).find(params[:order_id])
        request = ReturnRequest.request!(
          order: order,
          reason: params[:reason],
          resolution: params[:resolution],
          items: params[:items]
        )
        render_success(ReturnRequestSerializer.new(request).as_json, status: :created)
      end
    end
  end
end
