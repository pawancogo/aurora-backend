# frozen_string_literal: true

module Admin
  # Staff RMA queue: approve/reject a shopper's return, mark the parcel
  # received (restock), then complete it (flags a refund when the resolution
  # is refund — money still moves via the existing Payments::Refund click).
  class ReturnRequestsController < BaseController
    before_action -> { require_permission!("orders.read") }, only: %i[index show]
    before_action -> { require_permission!("orders.manage") }, only: %i[approve reject receive complete]
    before_action :set_return_request, only: %i[show approve reject receive complete]

    def index
      scope = ReturnRequest.includes(:customer, :order).recent
      result = ReturnRequest.search(params, scope: scope)
      @facets = result.facets
      @return_requests = result.records
    end

    def show
    end

    def approve
      @return_request.approve!(note: params[:admin_notes])
      redirect_to admin_return_request_path(@return_request), notice: "Return approved."
    rescue ReturnRequest::Error => e
      redirect_to admin_return_request_path(@return_request), alert: e.message
    end

    def reject
      @return_request.reject!(note: params[:admin_notes])
      redirect_to admin_return_request_path(@return_request), notice: "Return rejected."
    rescue ReturnRequest::Error => e
      redirect_to admin_return_request_path(@return_request), alert: e.message
    end

    def receive
      @return_request.receive!(admin_user: current_admin_user)
      redirect_to admin_return_request_path(@return_request), notice: "Return received and stock restocked."
    rescue ReturnRequest::Error, Inventory::Error => e
      redirect_to admin_return_request_path(@return_request), alert: e.message
    end

    def complete
      @return_request.complete!
      redirect_to admin_return_request_path(@return_request), notice: complete_notice
    rescue ReturnRequest::Error => e
      redirect_to admin_return_request_path(@return_request), alert: e.message
    end

    private

    def set_return_request
      @return_request = ReturnRequest.includes(:customer, :order, return_items: :order_item).find(params[:id])
    end

    def complete_notice
      if @return_request.refund?
        "Return completed. The payment is flagged for refund — use Refund payment on the order to send the money back."
      else
        "Exchange completed. The returned units are back in stock."
      end
    end
  end
end
